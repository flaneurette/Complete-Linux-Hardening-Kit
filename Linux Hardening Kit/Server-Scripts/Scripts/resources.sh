#!/bin/bash
PROCESS="${1}"
INTERVAL="${2:-5}"

if [ -z "$PROCESS" ]; then
    echo "Usage: $0 <process_name> [interval_seconds]"
    exit 1
fi

while true; do
    clear
    echo "=== Monitoring: $PROCESS ==="
    echo "Time: $(date)"
    echo "----------------------------"
    ps aux | grep "$PROCESS" | grep -v grep | \
        awk '{printf "PID: %s | CPU: %s%% | MEM: %s%% | CMD: %s\n", $2, $3, $4, $11}'
    sleep $INTERVAL
done
