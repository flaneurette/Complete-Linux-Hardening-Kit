# Apache-Honeypot
A simple PHP/Apache Honeypot that blocks automated scanners on IP.

### How it works
When a path, folder or file is entered or accessed (determined by rules in the root .htaccess), then a 3-strike system is triggered:

1. First time: Silent 404
2. Second time: Warning of impending IP block
3. Third time: IP Block.

> Usually, a scanner probes for multiple known files automatically. This triggers all three strikes, after which the IP is blocked at the firewall level by Fail2ban (iptables) for a configurable duration (default: 24 hours).

> The script attempts to distinguish intentional, top‑level navigation requests from embedded requests. Any access originating from HTML elements such as iframes, objects, or images is logged but excluded from strike counting. This prevents attacker‑induced or social‑engineering scenarios where a user could be blacklisted simply by visiting a page containing hidden or embedded requests to the honeypot URL.

> This mechanism does not stop a determined attacker who writes a fully custom bot and deliberately mimics browser navigation behavior. Its purpose is to eliminate off‑the‑shelf scanners and automated scripts commonly observed in the wild.

### Installation

Step 1: Upload /tmp/ and honeypot-strike.php to your web-root folder, usually /www/ (wait with the .htaccess)
> 1.1: Rename honeypot-strike.php to something unique, so scanners cannot find it. A UUID would be good.

Step 2: Modify the PHP file to add your preferences such as UNIQUE_KEY, and add your own IP.

> UNIQUE_KEY is required, so that scanners cannot guess the location of the honeypot!

> 2.1: Edit the .htaccess in the root, scroll to the end at the final rewrite rule, and rename: honeypot-strike.php to something unique. Then upload the .htaccess!

Step 3:

```
sudo mkdir /var/www/tmp/templates-UNIQUE_KEY/
sudo chown www-data:www-data /var/www/tmp/templates-UNIQUE_KEY/
sudo chmod 0700 -R /var/www/tmp/templates-UNIQUE_KEY/
```

Upload the template files to the above folder.

```bash
# Install required packages
sudo apt update
sudo apt install fail2ban

# Enable Apache modules
sudo a2enmod rewrite

# Create log file
sudo touch /var/www/tmp/honeypot-UNIQUE_KEY/UNIQUE_KEY-honeypot.log
sudo chown www-data:www-data /var/www/tmp/honeypot-UNIQUE_KEY/UNIQUE_KEY-honeypot.log
sudo chown www-data:adm /var/www/tmp/honeypot-UNIQUE_KEY/UNIQUE_KEY-honeypot.log
sudo chmod 0700 -R /var/www/tmp/honeypot-UNIQUE_KEY/
```

Step 4: Next step is to create fail2ban filters for IP banning:

### `/etc/fail2ban/filter.d/honeypot.conf` (Fail2ban Filter)

> sudo nano /etc/fail2ban/filter.d/honeypot.conf

```conf
# Fail2Ban filter for PHP honeypot strikes

[Definition]
failregex = ^ IP: <HOST> \| Strike: (?:[3-9]|\d{2,}) \|
ignoreregex = 
datepattern = {^LN-BEG}\[%%Y-%%m-%%d %%H:%%M:%%S\]
```

---

In this file, be sure to edit:
1. Path to log file:  /var/www/tmp/honeypot-UNIQUE_KEY/UNIQUE_KEY-honeypot.log
2. YOUR.IP.HERE: Your IP
3. Bantime, 86400 = ~24 hours.

> sudo nano /etc/fail2ban/jail.d/honeypot.conf
### `/etc/fail2ban/jail.d/honeypot.conf` (Fail2ban Jail)

```conf
[honeypot]
enabled = true
backend = polling
port = http,https
filter = honeypot
logpath = /var/www/tmp/honeypot-UNIQUE_KEY/UNIQUE_KEY-honeypot.log
maxretry = 1
findtime = 86400
bantime = 86400
action = iptables-multiport[name=honeypot, port="http,https", protocol=tcp]
ignoreip = 127.0.0.1/8 ::1 YOUR.IP.HERE
logtarget = /var/log/fail2ban-honeypot.log
```

### 5. Log rotate

```sudo nano /etc/logrotate.d/honeypot```

Add this block (remember to replace your unique key!):

```
/var/www/tmp/honeypot-UNIQUE_KEY/UNIQUE_KEY-honeypot.log {
    # Rotate logs daily
    daily
    # Keep 7 old logs
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0640 www-data adm
}
```

Test it:
```
sudo logrotate --force /etc/logrotate.d/honeypot
```

### 6. Restart services
```
sudo systemctl restart apache2
sudo systemctl restart fail2ban
sudo fail2ban-client reload honeypot
```
### 7. Verify setup
```
sudo fail2ban-client status honeypot
```

### 8. Clearing

If you need to clean and unban all IPs, perhaps in a large scale attack aimed at social engineering users, you could clear the jail to prevent legitimate users from accessing your service. 
It would be best to monitor the logs from time to time, especially if many "embed requests" are being made, which indicate a more sophisticated and customized attack to your server. However, this is very rare. We plan, in a future version, to send a single warning e-mail to the admin in such event, so that you could take immediate action and flush the jail temporarily while investigating the cause or source. But for now caution is advised.

To flush the honeypot jail:

`
sudo fail2ban-client set honeypot unbanip --all
`
