# Apache-Honeypot
A simple PHP/Apache Honeypot that blocks automated scanners on IP.

### How it works
When a path, folder or file is entered or accessed (determined by rules in the root .htaccess), then a 3-strike system is triggered:

1. First time: Silent 404
2. Second time: Warning of impending IP block
3. Third time: IP Block.

> Usually a scanner searches for multiple files automatically, which triggers all 3 strikes, and the IP is blocked in IP Tables by Fail2ban for a certain amount of time, default: 24hrs.

> The script also tries to determine if the source originated from navigation or document. It logs and stops any IP block that orginates from HTML elements, such as iframes, objects and images to prevent an attacker induced social engineering attempt, that may result in users being blacklisted when they click on a link with a hidden element that may trigger IP blocking.

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
