#!/bin/bash

set -e
shopt -s nullglob

read -p "How much MB to clean from journal logs? (default 500) " MBY
MBY=${MBY:-500}

echo "=== Disk usage before cleanup ==="
df -h /

echo "=== Cleaning journal logs ($MBY MB) ==="
sudo journalctl --vacuum-size=${MBY}M

echo "=== Cleaning package cache and autoremove ==="
sudo apt clean
sudo apt autoremove -y

echo "=== Cleaning old .gz archives older than 2 months ==="
sudo find /var/log -type f -name "*.gz" -mtime +60 -delete

echo "=== Cleaning tmp files older than 7 days ==="
sudo find /tmp -type f -atime +7 -delete
sudo find /var/tmp -type f -atime +7 -delete

echo "=== Disk usage after cleanup ==="
df -h /

echo "=== Done! ==="

RED='\033[0;31m'
NC='\033[0m' # No Color
echo -e "${RED}=====================================================================${NC}"
echo -e "${RED}    The script also cleared your BASH cache. However:                ${NC}"
echo -e "${RED}    REMEMBER to manually type: history -c                            ${NC}"
echo -e "${RED}    DO THIS NOW in every open terminal!                              ${NC}"
echo -e "${RED}    This prevents sensitive data from living in memory               ${NC}"
echo -e "${RED}    To prevent this: use a LEADING SPACE before a sensitive command  ${NC}"
echo -e "${RED}=====================================================================${NC}"

# Cleaning BASH history
> ~/.bash_history
for f in ~/.bash_history-*.tmp; do > "$f"; done

# Clearing less
> ~/.lesshst

# Clearing MySQL
> ~/.mysql_history

# Clear Python REPL history
> ~/.python_history

# Clearing Wget
> ~/.wget-hsts
> ~/wget-log
for f in ~/wget-log.*; do > "$f"; done

