#!/usr/bin/env bash
# audit.sh - quick external audit for SSH, Postfix, Dovecot, TLS and DNS
# Usage: ./audit.sh <TARGET_IP> <DOMAIN>
# Example: ./audit.sh 212.0.112.12 example.com

TARGET="$1"
DOMAIN="$2"

if [ -z "$TARGET" ] || [ -z "$DOMAIN" ]; then
	echo "Usage: $0 <TARGET_IP_or_HOST> <MAIL_DOMAIN>"
	exit 1
fi

# Install
sudo apt install nmap ssh-audit swaks -y

echo "== Basic nmap service/version scan =="
if command -v nmap >/dev/null 2>&1; then
	nmap -Pn -sV -p 21,22,25,80,443,465,587,143,110,993,995 --script=banner,smtp-enum-users,smtp-commands,smtp-open-relay,ssl-cert "$TARGET"
else
	echo "nmap not installed - skipping"
fi

echo
echo "== SSH audit (if ssh-audit installed) =="
if command -v ssh-audit >/dev/null 2>&1; then
	ssh-audit "$TARGET"
else
	echo "ssh-audit not installed. You can install/use: https://github.com/jtesta/ssh-audit"
fi

echo
echo "== TLS / STARTTLS checks using openssl s_client =="
# SMTP STARTTLS
echo "-- SMTP STARTTLS (port 25) --"
openssl s_client -starttls smtp -crlf -connect "${TARGET}:25" </dev/null 2>/dev/null | sed -n '1,24p'

echo
echo "-- Submission STARTTLS (port 587) --"
openssl s_client -starttls smtp -crlf -connect "${TARGET}:587" </dev/null 2>/dev/null | sed -n '1,24p'

echo
echo "-- SMTPS (port 465) --"
openssl s_client -connect "${TARGET}:465" </dev/null 2>/dev/null | sed -n '1,24p'

echo
echo "-- IMAPS (993) --"
openssl s_client -connect "${TARGET}:993" </dev/null 2>/dev/null | sed -n '1,24p'

echo
echo "-- POPS (995) --"
openssl s_client -connect "${TARGET}:995" </dev/null 2>/dev/null | sed -n '1,24p'

echo
echo "== SMTP functional tests with swaks (if available) =="
if command -v swaks >/dev/null 2>&1; then
	# Check whether server allows unauthenticated relay (attempt from external source)
	echo "-- swaks: try unauthenticated relay (should be rejected) --"
	swaks --to test@$DOMAIN --server "$TARGET" --from nobody@example.com --timeout 15
	# Try STARTTLS and try AUTH (note: will not give credentials; it tests ability to reach / advertise auth)
	echo "-- swaks: show HELO/EHLO, STARTTLS, auth methods --"
	swaks --server "$TARGET" --to test@"$DOMAIN" --from nobody@example.com --ehlo
else
	echo "swaks not installed - skipping mail functional tests. (install swaks to test auth/relay more thoroughly)"
fi

echo
echo "== DNS checks for mail (SPF/DKIM/DMARC) =="
echo "-- SPF (TXT) --"
dig +short TXT "$DOMAIN" | sed -n '1,20p'

echo
echo "-- MX records --"
dig +short MX "$DOMAIN" | sed -n '1,20p'

echo
echo "-- DMARC (for _dmarc.$DOMAIN) --"
dig +short TXT "_dmarc.$DOMAIN" | sed -n '1,20p'

echo
echo "== Helpful manual checks =="
echo "- Confirm smtpd_relay_restrictions includes reject_unauth_destination in Postfix."
echo "- Check /var/log/mail.log or journalctl -u postfix for unauthorized relays or lots of failures."
echo "- Ensure Dovecot has ssl = required and disable_plaintext_auth = yes."
echo "- If you see version strings in banners, consider hiding them or upgrading the software."

echo
echo "Audit script finished. Review the outputs above for obvious problems (open-relay responses, missing TLS, bad certs, version banners)."
