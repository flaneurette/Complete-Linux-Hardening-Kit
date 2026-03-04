#!/bin/bash

set -e
shopt -s nullglob

echo "=== Disk usage before cleanup ==="
df -h /

echo "=== Cleaning package cache and autoremove ==="
sudo apt clean
sudo apt autoremove -y

echo "=== Cleaning old .gz archives ==="
sudo find /var/log -type f -name "*.gz" -mtime +60 -delete

echo "=== Cleaning tmp files  ==="
sudo find /tmp -type f -atime +7 -delete
sudo find /var/tmp -type f -atime +7 -delete

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

# Shred it
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

sleep 1
sudo systemctl restart rsyslog
# Finish
history -c
truncate -s 0 ~/.bash_history
