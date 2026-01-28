#!/bin/bash

# File to store last known Tailscale devices
STATE_FILE="/var/tmp/tailscale_devices.txt"
EMAIL="example@example.com"
FROM="example@example.com"  # Use a valid sender address

# Get current device's hostname to exclude it
CURRENT_HOST=$(tailscale status --json | jq -r '.Self.HostName')

# Get current device list (IP + hostname), excluding self
CURRENT=$(tailscale status --json | \
    jq -r --arg host "$CURRENT_HOST" \
    '.Peer[] | select(.HostName != $host) | "\(.TailscaleIPs[0]) \(.HostName)"' | \
    sort)

# Read previous device list and sort it
if [ -f "$STATE_FILE" ]; then
    PREVIOUS=$(sort "$STATE_FILE")
else
    PREVIOUS=""
fi

# Compare current vs previous (find new devices)
if [ -n "$PREVIOUS" ]; then
    NEW=$(comm -13 <(echo "$PREVIOUS") <(echo "$CURRENT"))
    
    if [ -n "$NEW" ]; then
        echo -e "New Tailscale device(s) detected:\n\n$NEW" | \
            mail -s "Tailscale Alert: New device connected" -r "$FROM" "$EMAIL"
    fi
fi

# Update the state file
echo "$CURRENT" > "$STATE_FILE"
