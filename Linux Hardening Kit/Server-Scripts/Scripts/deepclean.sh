#!/bin/bash
# deepclean.sh once a week, Friday at 2:30am (choose different day and time, otherwise everyone knows you run it at that time!
# Or once a month, depending on how active you are as sysadmin. 
# Note: this script also clears trails potential attackers/bots might leave behind.
# crontab -e
# 30 2 * * 5 /bin/bash /home/scripts/deepclean.sh

set -euo pipefail
shopt -s nullglob

# Fail2ban
# --------
# If you have fail2ban, might want to make extra backup. (do the same for snort, if applicable)
# sudo fail2ban-client status sshd > /var/log/fail2ban_review_sshd_$(date +%Y%m%d).log
# sudo fail2ban-client banned >> /var/log/fail2ban_review_banned_$(date +%Y%m%d).log

ARCHIVE=~/logs_backup.tar.gz
ENCRYPTED=$ARCHIVE.gpg

# Comment these 3 lines with a: #, if you want encrypted backups:
[ -f "$ARCHIVE" ] && shred -u "$ARCHIVE"
[ -f "$ENCRYPTED" ] && shred -u "$ENCRYPTED"
sudo tar -czf $ARCHIVE /var/log --ignore-failed-read --warning=no-file-changed || true

# Encrypted backup
# -----------------
# Uncomment all these lines, if you want to encrypt all log files, and store it as GPG file:
# [ -f "$ARCHIVE" ] && shred -u "$ARCHIVE"
# [ -f "$ENCRYPTED" ] && shred -u "$ENCRYPTED"
# sudo tar -czf $ARCHIVE /var/log --ignore-failed-read --warning=no-file-changed || true
# gpg --recipient yourkey@email.com --encrypt $ARCHIVE
# [ -f "$ARCHIVE" ] && shred -u "$ARCHIVE"
# echo "=== Encrypted log archive saved: $ENCRYPTED ==="

echo "=== Disk usage before cleanup ==="
df -h /

echo "=== Cleaning package cache and autoremove ==="
sudo apt clean
sudo apt autoremove -y

echo "=== Cleaning journal logs  ==="
sudo journalctl --rotate
sudo journalctl --vacuum-time=1s

echo "=== Cleaning old .gz archives ==="
# sudo find /var/log -type f -name "*.gz" -mtime +60 -delete
sudo find /var/log -name "*.gz" -delete
sudo find /var/log -name "*.1" -delete
sudo find /var/log -name "*.old" -delete

echo "=== Cleaning tmp files  ==="
sudo find /tmp -type f -atime +7 -delete
sudo find /var/tmp -type f -atime +7 -delete

sudo truncate -s 0  /var/log/lynis.log
sudo truncate -s 0  /var/log/mail.log

echo "=== Deep clean... ==="

# Shred sensitive files.
shred -u /var/log/auth.log
touch /var/log/auth.log

sudo truncate -s 0 /var/log/syslog
sudo truncate -s 0 /var/log/kern.log
sudo truncate -s 0 /var/log/dpkg.log         # Debian/Ubuntu
sudo truncate -s 0 /var/log/apt/history.log
# sudo truncate -s 0 /var/log/messages       # RHEL/CentOS
# sudo truncate -s 0 /var/log/secure         # RHEL/CentOS
sudo rm -rf /var/cache/logwatch/*

echo "=== Disk usage after cleanup ==="
df -h /

RED='\033[0;31m'
NC='\033[0m' # No Color
echo -e "${RED}=====================================================================${NC}"
echo -e "${RED}    REMEMBER to manually type: history -c${NC}"
echo -e "${RED}    DO THIS NOW in every open terminal!${NC}"
echo -e "${RED}    This prevents from sensitive data living in memory               ${NC}"
echo -e "${RED}    To prevent this: use a LEADING SPACE before a sensitive command  ${NC}"
echo -e "${RED}=====================================================================${NC}"

# Shred it first.
shred -u ~/.bash_history
touch ~/.bash_history

# Cleaning BASH history and memory.
truncate -s 0 ~/.bash_history
# Clearing less
truncate -s 0 ~/.lesshst

# Clearing MySQL
truncate -s 0 ~/.mysql_history

# Clearing Wget
truncate -s 0 ~/.wget-hsts
truncate -s 0 ~/wget-log

for f in ~/.bash_history-*.tmp; do [ -f "$f" ] && > "$f"; done
for f in ~/wget-log.*; do [ -f "$f" ] && > "$f"; done

sudo systemctl stop auditd
sleep 1
sudo find /var/log/audit/ -type f -exec chmod 640 {} \;
sudo find /var/log/audit/ -type f -exec truncate -s 0 {} \;
sudo systemctl start auditd
sleep 1
sudo systemctl restart rsyslog
# Finish
history -c
truncate -s 0 ~/.bash_history
