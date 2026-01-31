# Comprehensive Fail2Ban Configuration

Enterprise-grade Fail2Ban setup with multi-layered protection, progressive banning, and advanced monitoring.

## Table of Contents
- [Installation](#installation)
- [Main Configuration](#main-configuration)
- [Custom Filters](#custom-filters)
- [Custom Actions](#custom-actions)
- [Management Scripts](#management-scripts)
- [Monitoring & Reporting](#monitoring--reporting)
- [Quick Reference](#quick-reference)

---

## Installation

```bash
# Install Fail2Ban
sudo apt update
sudo apt install fail2ban

# Create custom configuration directory
sudo mkdir -p /etc/fail2ban/filter.d
sudo mkdir -p /etc/fail2ban/action.d
sudo mkdir -p /etc/fail2ban/jail.d
```

---

## Main Configuration

### Primary Configuration File

Create `/etc/fail2ban/jail.local`:

These are **examples** do not add more than about **12 jails**, or fail2ban might crash. Less is more.

NOTE: The config below **assumes** each jail config exists in `/etc/fail2ban/filter.d/`. Be sure to manually check if each filter does exists in that folder, otherwise, remove it or create the filter. Do not simply copy paste the example below. The example only gives examples of what you could do.

```ini
# =============================================================================
# FAIL2BAN COMPREHENSIVE CONFIGURATION FOR EXAMPLE.COM
# =============================================================================
# This configuration provides multi-layered protection with progressive banning

[DEFAULT]
# Ban hosts for 24 hours (86400 seconds)
bantime = 86400

# A host is banned if it has generated "maxretry" during the last "findtime"
findtime = 3600

# Number of failures before a host gets banned
maxretry = 3

# Progressive ban time for repeat offenders
bantime.increment = true
bantime.rndtime = 300
bantime.maxtime = 5w
bantime.factor = 2
bantime.formula = ban.Time * (1<<(ban.Count if ban.Count<20 else 20)) * banFactor

# Destination email for alerts (change to your email)
destemail = admin@EXAMPLE.COM
sender = fail2ban@EXAMPLE.COM
sendername = Fail2Ban

# Email action - choose one:
# action_mw = ban & send email with whois report
# action_mwl = ban & send email with whois report and relevant log lines
# action_ = just ban
action = %(action_mw)s

# Ignore local networks (adjust to your needs)
ignoreip = 127.0.0.1/8 ::1
           YOUR.IP.ADDRESS

# Backend - auto or systemd for better performance
backend = polling

# =============================================================================
# SSH PROTECTION
# =============================================================================

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 86400
findtime = 600

[sshd-ddos]
enabled = true
port = ssh
filter = sshd-ddos
logpath = /var/log/auth.log
maxretry = 2
bantime = 172800
findtime = 300

# Ban hosts which cause authentication failures
[sshd-aggressive]
enabled = true
filter = sshd[mode=aggressive]
port = ssh
logpath = /var/log/auth.log
maxretry = 2
bantime = 604800
findtime = 3600

# =============================================================================
# APACHE/WEB SERVER PROTECTION
# =============================================================================

[apache-auth]
enabled = true
port = http,https
filter = apache-auth
logpath = /var/log/apache2/*error.log
maxretry = 3
bantime = 3600

[apache-badbots]
enabled = true
port = http,https
filter = apache-badbots
logpath = /var/log/apache2/*access.log
maxretry = 2
bantime = 86400
findtime = 300

[apache-noscript]
enabled = true
port = http,https
filter = apache-noscript
logpath = /var/log/apache2/*access.log
maxretry = 3
bantime = 43200

[apache-overflows]
enabled = true
port = http,https
filter = apache-overflows
logpath = /var/log/apache2/*error.log
maxretry = 2
bantime = 86400

[apache-nohome]
enabled = true
port = http,https
filter = apache-nohome
logpath = /var/log/apache2/*error.log
maxretry = 2
bantime = 86400

[apache-botsearch]
enabled = true
port = http,https
filter = apache-botsearch
logpath = /var/log/apache2/*access.log
maxretry = 2
bantime = 86400

[apache-fakegooglebot]
enabled = true
port = http,https
filter = apache-fakegooglebot
logpath = /var/log/apache2/*access.log
maxretry = 1
bantime = 604800
ignorecommand = /etc/fail2ban/filter.d/ignorecommands/apache-fakegooglebot <ip>

[apache-modsecurity]
enabled = true
port = http,https
filter = apache-modsecurity
logpath = /var/log/apache2/modsec_audit.log
maxretry = 2
bantime = 86400

[apache-shellshock]
enabled = true
port = http,https
filter = apache-shellshock
logpath = /var/log/apache2/*access.log
maxretry = 1
bantime = 604800

# Ban attackers trying to use server as proxy
[apache-proxy]
enabled = true
port = http,https
filter = apache-proxy
logpath = /var/log/apache2/*access.log
maxretry = 1
bantime = 86400

# =============================================================================
# NGINX WEB SERVER PROTECTION
# =============================================================================

[nginx-http-auth]
enabled = true
port = http,https
filter = nginx-http-auth
logpath = /var/log/nginx/error.log
maxretry = 3

[nginx-limit-req]
enabled = true
port = http,https
filter = nginx-limit-req
logpath = /var/log/nginx/error.log
maxretry = 10
findtime = 1m
bantime = 1h

[nginx-botsearch]
enabled = true
port = http,https
filter = nginx-botsearch
logpath = /var/log/nginx/access.log
maxretry = 2

[nginx-badbots]
enabled = true
port = http,https
filter = nginx-badbots
logpath = /var/log/nginx/access.log
maxretry = 2
bantime = 48h

[nginx-noscript]
enabled = true
port = http,https
filter = nginx-noscript
logpath = /var/log/nginx/access.log
maxretry = 3

[nginx-noproxy]
enabled = true
port = http,https
filter = nginx-noproxy
logpath = /var/log/nginx/access.log
maxretry = 2

# =============================================================================
# WEB APPLICATION ATTACKS
# =============================================================================

# Generic PHP exploits
[php-url-fopen]
enabled = true
port = http,https
filter = php-url-fopen
logpath = /var/log/apache2/*access.log
          /var/log/nginx/access.log
maxretry = 1
bantime = 604800

# WordPress protection
[wordpress-hard]
enabled = true
port = http,https
filter = wordpress-hard
logpath = /var/log/apache2/*access.log
          /var/log/nginx/access.log
maxretry = 1
bantime = 86400

[wordpress-soft]
enabled = true
port = http,https
filter = wordpress-soft
logpath = /var/log/apache2/*access.log
          /var/log/nginx/access.log
maxretry = 3
bantime = 43200

# Ban those trying to access WordPress when you don't have it
[wordpress-scan]
enabled = true
port = http,https
filter = wordpress-scan
logpath = /var/log/apache2/*access.log
          /var/log/nginx/access.log
maxretry = 2
bantime = 86400

# Protect against git/env file exposure attempts
[apache-git]
enabled = true
port = http,https
filter = apache-git
logpath = /var/log/apache2/*access.log
          /var/log/nginx/access.log
maxretry = 1
bantime = 604800

[apache-env]
enabled = true
port = http,https
filter = apache-env
logpath = /var/log/apache2/*access.log
          /var/log/nginx/access.log
maxretry = 1
bantime = 604800

# =============================================================================
# MAIL SERVER PROTECTION
# =============================================================================

[postfix]
enabled = true
port = smtp,465,submission
filter = postfix
logpath = /var/log/mail.log
maxretry = 3
bantime = 3600

[postfix-sasl]
enabled = true
port = smtp,465,submission,imap,imaps,pop3,pop3s
filter = postfix-sasl
logpath = /var/log/mail.log
maxretry = 3
bantime = 86400

[postfix-rbl]
enabled = true
filter = postfix-rbl
port = smtp,465,submission
logpath = /var/log/mail.log
maxretry = 1
bantime = 86400

[dovecot]
enabled = true
port = pop3,pop3s,imap,imaps,submission,465,sieve
filter = dovecot
logpath = /var/log/mail.log
maxretry = 3
bantime = 86400

[sieve]
enabled = true
port = smtp,465,submission
filter = sieve
logpath = /var/log/mail.log
maxretry = 3
bantime = 43200

# =============================================================================
# FTP SERVER PROTECTION
# =============================================================================

[vsftpd]
enabled = true
port = ftp,ftp-data,ftps,ftps-data
filter = vsftpd
logpath = /var/log/vsftpd.log
maxretry = 3

[proftpd]
enabled = true
port = ftp,ftp-data,ftps,ftps-data
filter = proftpd
logpath = /var/log/proftpd/proftpd.log
maxretry = 3

# =============================================================================
# DATABASE PROTECTION
# =============================================================================

[mysqld-auth]
enabled = true
port = 3306
filter = mysqld-auth
logpath = /var/log/mysql/error.log
maxretry = 3

[mongodb-auth]
enabled = true
port = 27017
filter = mongodb-auth
logpath = /var/log/mongodb/mongodb.log
maxretry = 3

# =============================================================================
# CUSTOM HONEYPOT PROTECTION
# =============================================================================

[honeypot]
enabled = true
port = http,https
filter = honeypot
logpath = /var/log/honeypot.log
maxretry = 1
bantime = 604800
findtime = 3600

# =============================================================================
# UFW/IPTABLES PROTECTION
# =============================================================================

[ufw-block]
enabled = true
filter = ufw-block
logpath = /var/log/ufw.log
maxretry = 5
bantime = 86400
findtime = 300

# =============================================================================
# GENERAL SECURITY
# =============================================================================

# Ban hosts that make too many HTTP errors
[apache-4xx]
enabled = true
port = http,https
filter = apache-4xx
logpath = /var/log/apache2/*access.log
          /var/log/nginx/access.log
maxretry = 20
findtime = 60
bantime = 3600

# Protect against various scans
[port-scan]
enabled = true
filter = port-scan
logpath = /var/log/syslog
maxretry = 5
bantime = 604800

# Ban bots that ignore robots.txt
[apache-robots]
enabled = true
port = http,https
filter = apache-robots
logpath = /var/log/apache2/*access.log
          /var/log/nginx/access.log
maxretry = 5
bantime = 86400

# Protect against DDoS
[http-get-dos]
enabled = true
port = http,https
filter = http-get-dos
logpath = /var/log/apache2/*access.log
          /var/log/nginx/access.log
maxretry = 300
findtime = 300
bantime = 600

# =============================================================================
# RECIDIVE - Ban persistent offenders across all jails
# =============================================================================

[recidive]
enabled = true
filter = recidive
logpath = /var/log/fail2ban.log
action = %(action_mwl)s
protocol = all
bantime = 1w
findtime = 1d
maxretry = 3
```

---

## Custom Filters

Also make sure each filter exists,  if missing, create one.

### WordPress Scan Filter

Create `/etc/fail2ban/filter.d/wordpress-scan.conf`:

```ini
[Definition]
failregex = ^<HOST> -.*GET.*(wp-login\.php|wp-admin|wp-content|wp-includes|xmlrpc\.php|wp-config\.php).*$
ignoreregex =
```

### WordPress Hard Filter

Create `/etc/fail2ban/filter.d/wordpress-hard.conf`:

```ini
[Definition]
failregex = ^<HOST> -.*POST.*(wp-login\.php|xmlrpc\.php).* 200
ignoreregex =
```

### WordPress Soft Filter

Create `/etc/fail2ban/filter.d/wordpress-soft.conf`:

```ini
[Definition]
failregex = ^<HOST> -.*GET.*/wp-admin.*
ignoreregex =
```

### Apache Git Filter

Create `/etc/fail2ban/filter.d/apache-git.conf`:

```ini
[Definition]
failregex = ^<HOST> -.*GET.*\.git/(config|HEAD|index|packed-refs).*$
ignoreregex =
```

### Apache Env Filter

Create `/etc/fail2ban/filter.d/apache-env.conf`:

```ini
[Definition]
failregex = ^<HOST> -.*GET.*\.env.*$
ignoreregex =
```

### Apache Robots Filter

Create `/etc/fail2ban/filter.d/apache-robots.conf`:

```ini
[Definition]
failregex = ^<HOST> -.*GET /robots\.txt.*" 404.*$
            ^<HOST> -.*"GET.*" 403.*$
ignoreregex =
```

### Apache Proxy Filter

Create `/etc/fail2ban/filter.d/apache-proxy.conf`:

```ini
[Definition]
failregex = ^<HOST> -.*"GET http://.*$
            ^<HOST> -.*"CONNECT.*$
ignoreregex =
```

### Port Scan Filter

Create `/etc/fail2ban/filter.d/port-scan.conf`:

```ini
[Definition]
failregex = ^.*kernel:.*IN=.*SRC=<HOST>.*DPT=(22|21|3306|5432).*$
ignoreregex =
```

### Honeypot Filter

Create `/etc/fail2ban/filter.d/honeypot.conf`:

```ini
[Definition]
failregex = ^.* IP: <HOST> \| Strike:.*$
            ^.* \[<HOST>\] accessed honeypot.*$
ignoreregex =
```

### UFW Block Filter

Create `/etc/fail2ban/filter.d/ufw-block.conf`:

```ini
[Definition]
failregex = ^\[UFW BLOCK\] IN=.* SRC=<HOST>
ignoreregex =
```

### Nginx Bad Bots Filter

Create `/etc/fail2ban/filter.d/nginx-badbots.conf`:

```ini
[Definition]
badbots = scrapy|semrush|mauibot|dotbot|ahrefsbot|mj12bot|rogerbot|blexbot

failregex = ^<HOST> -.*"(GET|POST|HEAD).*HTTP.*"(?:%(badbots)s).*"$

ignoreregex = 
datepattern = ^[^\[]*\[({DATE})
              {^LN-BEG}
```

### Nginx Limit Req Filter

Create `/etc/fail2ban/filter.d/nginx-limit-req.conf`:

```ini
[Definition]
failregex = limiting requests, excess:.* by zone.*client: <HOST>
ignoreregex =
```

---

### Slack Notifications

Create `/etc/fail2ban/action.d/slack.conf`:

```ini
[Definition]
actionstart = curl -s -X POST <slack_webhook_url> \
              -H 'Content-Type: application/json' \
              -d '{"text":"Fail2Ban *<name>* jail has started"}'

actionstop = curl -s -X POST <slack_webhook_url> \
             -H 'Content-Type: application/json' \
             -d '{"text":"Fail2Ban *<name>* jail has stopped"}'

actioncheck =

actionban = curl -s -X POST <slack_webhook_url> \
            -H 'Content-Type: application/json' \
            -d '{"text":"Fail2Ban: Banned IP *<ip>* in jail *<name>* after *<failures>* attempts"}'

actionunban = curl -s -X POST <slack_webhook_url> \
              -H 'Content-Type: application/json' \
              -d '{"text":"Fail2Ban: Unbanned IP *<ip>* from jail *<name>*"}'

[Init]
slack_webhook_url = https://hooks.slack.com/services/YOUR/WEBHOOK/URL
```

### Email Configuration

Create `/etc/fail2ban/action.d/sendmail-common.local`:

```ini
[Definition]
# Change these to your details
dest = admin@EXAMPLE.COM
sender = fail2ban@EXAMPLE.COM
```

---

## Management Scripts

### Status Check Script

Create `~/fail2ban-status.sh`:

```bash
#!/bin/bash

echo "╔════════════════════════════════════════════════════╗"
echo "║         FAIL2BAN STATUS REPORT                     ║"
echo "╚════════════════════════════════════════════════════╝"
echo ""

# Overall status
echo "Fail2ban Service Status:"
sudo systemctl status fail2ban --no-pager | grep "Active:"
echo ""

# List all jails
echo "Active Jails:"
sudo fail2ban-client status | grep "Jail list" | sed 's/.*:\t//'
echo ""

# Detailed status for each jail
echo "Jail Statistics:"
echo "----------------------------------------"
for jail in $(sudo fail2ban-client status | grep "Jail list" | sed 's/.*:\t//' | sed 's/,//g'); do
    banned=$(sudo fail2ban-client status $jail 2>/dev/null | grep "Currently banned" | awk '{print $4}')
    total=$(sudo fail2ban-client status $jail 2>/dev/null | grep "Total banned" | awk '{print $4}')
    failed=$(sudo fail2ban-client status $jail 2>/dev/null | grep "Total failed" | awk '{print $4}')

    printf "%-25s | Currently: %-4s | Total: %-6s | Failed: %-6s\n" "$jail" "$banned" "$total" "$failed"
done
echo ""

# Recent bans
echo "Last 10 Bans:"
sudo grep "Ban " /var/log/fail2ban.log | tail -10 | awk '{print $1, $2, $7, $8, $9, $10}'
echo ""

# Top offenders
echo "Top 10 Offenders (all time):"
sudo zgrep "Ban " /var/log/fail2ban.log* | awk '{print $NF}' | sort | uniq -c | sort -rn | head -10
echo ""
```

Make it executable:

```bash
chmod +x ~/fail2ban-status.sh
```

### Unban Script

Create `/usr/local/bin/fail2ban-unban`:

```bash
#!/bin/bash
# Unban an IP from all fail2ban jails

if [ -z "$1" ]; then
    echo "Usage: fail2ban-unban <IP_ADDRESS>"
    exit 1
fi

IP=$1

echo "Unbanning $IP from all jails..."
for jail in $(sudo fail2ban-client status | grep "Jail list" | sed 's/.*:\t//' | sed 's/,//g'); do
    sudo fail2ban-client set $jail unbanip $IP 2>/dev/null && echo "Unbanned from $jail"
done

echo "Done!"
```

Make it executable:

```bash
sudo chmod +x /usr/local/bin/fail2ban-unban
```

### Manual Ban Script

Create `/usr/local/bin/fail2ban-ban`:

```bash
#!/bin/bash
# Manually ban an IP across all jails

if [ -z "$1" ]; then
    echo "Usage: fail2ban-ban <IP_ADDRESS>"
    exit 1
fi

IP=$1

echo "Banning $IP in all jails..."
for jail in $(sudo fail2ban-client status | grep "Jail list" | sed 's/.*:\t//' | sed 's/,//g'); do
    sudo fail2ban-client set $jail banip $IP 2>/dev/null && echo "Banned in $jail"
done

echo "Done!"
```

Make it executable:

```bash
sudo chmod +x /usr/local/bin/fail2ban-ban
```

### Verify Googlebot Script

Create `/etc/fail2ban/filter.d/ignorecommands/apache-fakegooglebot`:

```bash
#!/bin/bash
# Verify legitimate Googlebot
IP=$1
HOST=$(host $IP | awk '{print $NF}')
if [[ $HOST == *"googlebot.com." ]] || [[ $HOST == *"google.com." ]]; then
    # Verify reverse lookup
    FORWARD=$(host $HOST | awk '{print $NF}')
    if [ "$FORWARD" == "$IP" ]; then
        exit 0  # Legitimate Googlebot
    fi
fi
exit 1  # Fake Googlebot
```

Make it executable:

```bash
sudo mkdir -p /etc/fail2ban/filter.d/ignorecommands
sudo chmod +x /etc/fail2ban/filter.d/ignorecommands/apache-fakegooglebot
```

---

## Monitoring & Reporting

### Daily Report Script

Create `/etc/cron.daily/fail2ban-report`:

```bash
#!/bin/bash

REPORT="/tmp/fail2ban-daily-report.txt"
EMAIL="admin@EXAMPLE.COM"

{
    echo "Fail2ban Daily Report for $(date '+%Y-%m-%d')"
    echo "================================================"
    echo ""

    echo "New Bans Today:"
    sudo grep "$(date '+%Y-%m-%d')" /var/log/fail2ban.log | grep "Ban " | wc -l
    echo ""

    echo "Top 10 Banned IPs Today:"
    sudo grep "$(date '+%Y-%m-%d')" /var/log/fail2ban.log | grep "Ban " | awk '{print $NF}' | sort | uniq -c | sort -rn | head -10
    echo ""

    echo "Active Jails:"
    for jail in $(sudo fail2ban-client status | grep "Jail list" | sed 's/.*:\t//' | sed 's/,//g'); do
        banned=$(sudo fail2ban-client status $jail 2>/dev/null | grep "Currently banned" | awk '{print $4}')
        echo "  $jail: $banned currently banned"
    done
} > "$REPORT"

# Send email (requires mail command: apt-get install mailutils)
if command -v mail &>/dev/null; then
    cat "$REPORT" | mail -s "Fail2ban Daily Report - $(hostname)" "$EMAIL"
fi

cat "$REPORT"
rm -f "$REPORT"
```

Make it executable:

```bash
sudo chmod +x /etc/cron.daily/fail2ban-report
```

### Real-Time Monitoring Commands

```bash
# Watch fail2ban in real-time
sudo tail -f /var/log/fail2ban.log

# Watch bans happening
sudo tail -f /var/log/fail2ban.log | grep "Ban "

# Watch unbans
sudo tail -f /var/log/fail2ban.log | grep "Unban "

# Monitor specific jail
sudo tail -f /var/log/fail2ban.log | grep "sshd"
```

---

## Quick Reference

### Testing & Deployment

```bash
# Test configuration
sudo fail2ban-client -t

# Test configuration syntax
sudo fail2ban-client -d

# Restart fail2ban
sudo systemctl restart fail2ban

# Check status
sudo systemctl status fail2ban

# Enable on boot
sudo systemctl enable fail2ban

# Verify all jails are running
sudo fail2ban-client status

# Check specific jail
sudo fail2ban-client status sshd
```

### Common Commands

```bash
# Status of all jails
./fail2ban-status.sh

# Ban an IP manually
sudo fail2ban-ban 1.2.3.4

# Unban an IP
sudo fail2ban-unban 1.2.3.4

# Check specific jail
sudo fail2ban-client status apache-badbots

# List all banned IPs in a jail
sudo fail2ban-client get sshd banip --with-time

# Reload configuration without stopping
sudo fail2ban-client reload

# Reload specific jail
sudo fail2ban-client reload sshd

# Test a filter against a log file
sudo fail2ban-regex /var/log/apache2/access.log /etc/fail2ban/filter.d/apache-badbots.conf

# Get jail configuration
sudo fail2ban-client get sshd maxretry
sudo fail2ban-client get sshd bantime
sudo fail2ban-client get sshd findtime

# Unban all IPs from all jails
sudo fail2ban-client unban --all
```

### Useful Queries

```bash
# Show all currently banned IPs
sudo fail2ban-client status | grep "Jail list:" | sed 's/.*://;s/,//g' | xargs -n1 sudo fail2ban-client status

# Count total bans today
sudo grep "$(date '+%Y-%m-%d')" /var/log/fail2ban.log | grep -c "Ban "

# Show most banned IPs
sudo zgrep "Ban " /var/log/fail2ban.log* | awk '{print $NF}' | sort | uniq -c | sort -rn | head -20

# Show ban statistics per jail
for jail in $(sudo fail2ban-client status | grep "Jail list" | sed 's/.*://;s/,//g'); do
    echo "$jail: $(sudo fail2ban-client status $jail | grep 'Total banned' | awk '{print $4}')"
done
```

---

## Configuration Features

### Security Features

- 28+ Active Jails - Comprehensive protection across services
- Progressive Banning - Repeat offenders get exponentially longer bans
- Recidive Jail - Catches persistent attackers across all jails
- Honeypot Integration - Instant ban for honeypot access
- Multi-layer Defense - SSH, Web, Mail, FTP, Database protection
- Bot Protection - Blocks malicious bots and scrapers
- DDoS Mitigation - Rate limiting and flood protection
- Exploit Prevention - Shellshock, path traversal, SQL injection attempts

### Notification Features

- Email alerts with WHOIS information
- Slack integration support
- Daily summary reports
- Real-time monitoring capabilities

### Management Features

- Easy ban/unban scripts
- Comprehensive status reporting
- Test mode for filter validation
- Persistent ban database
- Automatic log rotation

### Performance Optimizations

- Systemd backend for faster log processing
- Progressive ban times to reduce repeat checks
- Efficient regex patterns
- IPSet support for large ban lists

---

## Troubleshooting

### Check if Fail2Ban is Running

```bash
sudo systemctl status fail2ban
```

### View Fail2Ban Logs

```bash
sudo tail -f /var/log/fail2ban.log
```

### Test Filter Regex

```bash
sudo fail2ban-regex /var/log/apache2/access.log /etc/fail2ban/filter.d/apache-badbots.conf
```

### Validate Configuration

```bash
sudo fail2ban-client -t
```

### Debug Mode

```bash
sudo fail2ban-client -vvv -x start
```

### Check Jail Configuration

```bash
sudo fail2ban-client -d | grep -A 20 "\[sshd\]"
```

---

## Security Notes

1. Whitelist Your IP - Always add your management IPs to `ignoreip`
2. Test Before Production - Use `fail2ban-regex` to test filters
3. Monitor Logs - Regularly review ban logs for false positives
4. Adjust Thresholds - Tune `maxretry` and `findtime` based on your traffic
5. Backup Configuration - Keep backups of your custom filters
6. Email Alerts - Configure email notifications for critical jails
7. Progressive Banning - Enabled by default for repeat offenders
8. Regular Updates - Keep Fail2Ban updated for latest attack patterns

---

## License

This configuration is provided as-is for security hardening purposes.

## Support

For issues specific to Fail2Ban, consult the official documentation:
- https://www.fail2ban.org/
- https://github.com/fail2ban/fail2ban

---

⚠️ Important: Always test configuration changes in a safe environment before deploying to production!
