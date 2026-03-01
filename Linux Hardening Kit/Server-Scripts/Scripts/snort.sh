#!/bin/bash
# Snort alert monitor
# Usage: ./snort.sh [filter]

LOGFILE=$(ls -t /var/log/snort/snort.alert.fast 2>/dev/null | head -1)

if [ -z "$LOGFILE" ]; then
    echo "No Snort alert file found"
    exit 1
fi

echo "Watching: $LOGFILE"
echo "Press Ctrl+C to stop"
echo "---"

if [ -n "$1" ]; then
    # Filter by IP or keyword if argument provided
    tail -f "$LOGFILE" | grep --line-buffered "$1"
else
    tail -f "$LOGFILE"
fi