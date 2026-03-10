# Simple IDS.

```
sudo apt install inotify-tools mailutils
```

Watcher script:

```
nano /usr/local/sbin/auth_watcher.sh
```

Paste:

```
#!/bin/bash
# /usr/local/sbin/auth_watcher.sh

WATCH_FILE="/var/log/auth.log"
SCRIPT_TO_RUN="/usr/local/sbin/auth_monitor.sh"

inotifywait -m -e modify "$WATCH_FILE" |
while read -r directory event filename; do
    echo "[$(date)] auth.log changed — running monitor"
    bash "$SCRIPT_TO_RUN"
done
```

Systemd

```
nano /etc/systemd/system/auth-watcher.service
```

Paste:

```
# /etc/systemd/system/auth-watcher.service
[Unit]
Description=Auth Log Watcher
After=network.target

[Service]
ExecStart=/usr/local/sbin/auth_watcher.sh
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

Monitoring script:

```
nano /usr/local/sbin/auth_monitor.sh
```

Best to use a `e-mailaccount` not served on the same server, as it could be wiped!
Best practise: send an e-mail to another server/mailaccount.

Paste and edit email/ip:

```
#!/bin/bash

# ======================================================================
# auth_monitor.sh - Authentication Log Monitor with Email Alerts
# ======================================================================
# Sends email alerts on unauthorized login attempts
# Supports IP whitelisting
# Only alerts ONCE per new IP (no mailbox spam)
# ======================================================================
# SETUP:
#   1. chmod +x auth_monitor.sh
#   2. Edit WHITELISTED IPs below
# ======================================================================

# ----------- CONFIGURATION -----------

EMAIL_TO="info@example.com"
EMAIL_FROM="auth-monitor@$(hostname)"
EMAIL_SUBJECT="[SECURITY ALERT] Unauthorized Login Attempt on $(hostname)"

WHITELIST_IP_1="192.168.1.10"
WHITELIST_IP_2="10.0.0.5"
WHITELIST_IP_3="203.0.113.42"

AUTH_LOG="/var/log/auth.log"
SEEN_IPS_FILE="/var/lib/auth_monitor/seen_ips.txt"

# ----------- INIT -----------

mkdir -p /var/lib/auth_monitor
touch "$SEEN_IPS_FILE"

# ----------- EXTRACT ALL IPs FROM LOG -----------

ALL_IPS=$(grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' "$AUTH_LOG" | sort -u)

# ----------- LOOP OVER IPs -----------

for IP in $ALL_IPS; do

    # Skip whitelisted IPs
    if [ "$IP" = "$WHITELIST_IP_1" ] || \
       [ "$IP" = "$WHITELIST_IP_2" ] || \
       [ "$IP" = "$WHITELIST_IP_3" ]; then
        continue
    fi

    # Skip already seen IPs
    if grep -qF "$IP" "$SEEN_IPS_FILE"; then
        continue
    fi

    # Mark IP as seen
    echo "$IP" >> "$SEEN_IPS_FILE"

    # Get all log lines for this IP
    LOG_LINES=$(grep "$IP" "$AUTH_LOG")

    # Send email
    {
        echo "=============================================="
        echo " SECURITY ALERT - Unauthorized Login Activity"
        echo "=============================================="
        echo ""
        echo "Host      : $(hostname)"
        echo "Time      : $(date '+%Y-%m-%d %H:%M:%S')"
        echo "New IP    : $IP"
        echo ""
        echo "----------------------------------------------"
        echo " LOG LINES FOR THIS IP:"
        echo "----------------------------------------------"
        echo "$LOG_LINES"
        echo ""
        echo "----------------------------------------------"
        echo " CURRENT ACTIVE SESSIONS (w):"
        echo "----------------------------------------------"
        w
        echo ""
        echo "----------------------------------------------"
        echo " LAST LOGINS (last -n 10):"
        echo "----------------------------------------------"
        last -n 10
        echo ""
        echo "----------------------------------------------"
        echo " FAILED LOGIN HISTORY (lastb -n 10):"
        echo "----------------------------------------------"
        lastb -n 10 2>/dev/null || echo "(lastb requires root or adm group)"
        echo ""
        echo "----------------------------------------------"
        echo " ALL KNOWN SUSPICIOUS IPs SO FAR:"
        echo "----------------------------------------------"
        cat "$SEEN_IPS_FILE"
        echo ""
        echo "=============================================="
        echo " Automated message from auth_monitor.sh"
        echo "=============================================="
    } | mail -s "$EMAIL_SUBJECT" -a "From: $EMAIL_FROM" "$EMAIL_TO"

    echo "[auth_monitor] Alert sent for IP: $IP"

done

exit 0

```

Finally:

```
sudo chmod +x /usr/local/sbin/auth_monitor.sh
sudo chmod +x /usr/local/sbin/auth_watcher.sh
sudo systemctl daemon-reload
sudo systemctl enable auth-watcher
sudo systemctl start auth-watcher
sudo systemctl status auth-watcher
```
