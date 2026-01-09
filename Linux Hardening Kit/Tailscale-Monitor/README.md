# Tailscale-Monitor
Monitors Tailscale connections and sends email alerts when new devices join your network.

## Why Use This?

While Tailscale is secure, this script provides an **independent monitoring layer** that protects against:
- Compromised Tailscale admin accounts
- Unauthorized device approvals
- Audit log tampering
- Security misconfigurations

**Defense in depth**: If your Tailscale web console is compromised, you might never know it through Tailscale's own logging. This script provides out-of-band alerting that runs independently on your infrastructure.

## Features

- Detects new devices connecting to your Tailscale network
- Excludes the monitoring host (won't alert on itself)
- Email notifications with device details
- Persistent state tracking between runs
- Logging for audit trail
- Independent of Tailscale's admin console

## Prerequisites

```bash
sudo apt update
sudo apt install mailutils jq
```

**Note**: Ensure your mail system is configured. Test with:
```bash
echo "Test" | mail -s "Test Subject" your@email.com
```

## Installation

1. **Create the script:**
```bash
sudo nano /usr/local/bin/tailscale-monitor.sh
```

2. **Paste the script content** (see `tailscale-monitor.sh`)

3. **Edit configuration:**
   - Set `EMAIL="your@email.com"`
   - Optionally set `FROM="tailscale-monitor@yourdomain.com"`

4. **Make executable:**
```bash
sudo chmod +x /usr/local/bin/tailscale-monitor.sh
```

5. **Test the script:**
```bash
sudo /usr/local/bin/tailscale-monitor.sh
```

## Setup Automated Monitoring

Add to root's crontab:
```bash
sudo crontab -e
```

Check every 5 minutes:
```
*/5 * * * * /usr/local/bin/tailscale-monitor.sh > /dev/null 2>&1
```

Or every minute for faster detection:
```
* * * * * /usr/local/bin/tailscale-monitor.sh > /dev/null 2>&1
```

## Tailscale Security Settings

**Important**: This script is a monitoring tool, not a prevention mechanism. Configure Tailscale's built-in security:

### In Tailscale Admin Console (https://tailscale.com/):

1. **Enable Device Authorization:**
   - Go to Settings → Keys
   - Enable "Require device authorization"
   - All new devices must be manually approved

2. **Set Key Expiry:**
   - Go to Settings → Keys
   - Configure default key expiry (recommended: 30-90 days)
   - Existing devices may need re-authentication

3. **Enable MFA/2FA:**
   - Go to Settings → Users
   - Require multi-factor authentication

4. **Configure ACLs:**
   - Go to Access Controls
   - Define policies limiting device access
   - Follow principle of least privilege

5. **Enable Audit Logging:**
   - Review logs regularly for suspicious activity set --key-expiry=30d

### Confirm:
-  Enable device authorization (manual approval required)
-  Set up MFA/2FA on your Tailscale account
-  Configure ACL policies to limit device access
-  Enable audit logging
-  Review connected devices regularly

## When You Receive an Alert

**Immediate actions:**

1. Check your email for device details (IP, hostname, OS, user)
2. Log into Tailscale admin console
3. Verify if the connection was authorized
4. If unauthorized:
   - Revoke device access immediately
   - Change your Tailscale account password
   - Enable/verify MFA is active
   - Review audit logs for other suspicious activity
   - Check ACLs for unauthorized changes
5. If authorized but unexpected:
   - Verify device owner identity through another channel
   - Review device details and approval history

## File Locations

- Script: `/usr/local/bin/tailscale-monitor.sh`
- State file: `/var/tmp/tailscale_devices.txt`
- Log file: `/var/log/tailscale-watch.log`

## Optional Hardening

### Make script immutable
Prevents modification even by root:
```bash
sudo chattr +i /usr/local/bin/tailscale-monitor.sh
```

To modify later:
```bash
sudo chattr -i /usr/local/bin/tailscale-monitor.sh
```

### Protect state file
```bash
sudo chmod 600 /var/tmp/tailscale_devices.txt
sudo chown root:root /var/tmp/tailscale_devices.txt
```

## Troubleshooting

### No emails received:
```bash
# Check mail logs
sudo tail -f /var/log/mail.log

# Verify mail queue
mailq

# Test mail configuration
echo "Test" | mail -s "Test" your@email.com
```

### Script not running:
```bash
# Check cron logs
sudo grep CRON /var/log/syslog

# Verify crontab
sudo crontab -l

# Test script manually
sudo /usr/local/bin/tailscale-monitor.sh
```

### False positives:
The first run after installation will detect all existing devices as "new". This is normal and expected.

## Limitations

- **Not a prevention tool**: Alerts are sent *after* a device connects
- **Email delays**: Notifications may be delayed by seconds to minutes
- **Local monitoring only**: Only monitors the server where it's installed
- **Can be bypassed**: If the monitoring server is compromised

## Security Considerations

This script is part of a **defense-in-depth strategy**:

1. **Prevention**: Tailscale device authorization (primary security)
2. **Detection**: This monitoring script (backup verification)
3. **Limitation**: ACLs to minimize damage if compromised
4. **Response**: Incident response procedures

**Never rely on a single security measure.**

## License

MIT

## Contributing

Contributions welcome! Please open an issue or pull request.
