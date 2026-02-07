#!/bin/bash

set -e

LOG="/var/log/service-watchdog.log"
# Check systemd service. 
# Add a systemd service here:
SERVICE="iptables-restore-onboot.service"

check_and_start() {
    SERVICE="$1"

    if ! systemctl is-active --quiet "$SERVICE"; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $SERVICE was down, starting it" >> "$LOG"
        systemctl start "$SERVICE"
    fi
}

check_and_start apache2
check_and_start postfix
check_and_start dovecot

# Check if the service exists
if ! systemctl list-unit-files | grep -q "^$SERVICE"; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $SERVICE does not exist!" >> "$LOG"
    exit 1
fi

# Check if the service is enabled on boot
if systemctl is-enabled --quiet "$SERVICE"; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $SERVICE is enabled" >> "$LOG"
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $SERVICE is NOT enabled" >> "$LOG"
    systemctl enable "$SERVICE"
fi

# Check if the service is running
if systemctl is-active --quiet "$SERVICE"; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $SERVICE is running" >> "$LOG"
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $SERVICE is NOT running" >> "$LOG"
    systemctl start "$SERVICE"
fi
