#!/bin/bash

echo "=== ALL RUNNING PROCESSES ==="
echo "PID | PPID | USER | CPU% | MEM% | COMMAND"
echo "------------------------------------------------"
ps -eo pid,ppid,user,%cpu,%mem,comm --sort=-%cpu | head -50
echo "------------------------------------------------"

read -p "Enter process name (partial match) to kill: " PROCESS

# Find matching processes, case-insensitive, include children
PIDS=$(ps -eo pid,ppid,comm | grep -i "$PROCESS" | awk '{print $1}')

if [ -z "$PIDS" ]; then
    echo "No processes found matching '$PROCESS'"
    exit 0
fi

echo "Found processes:"
ps -fp $PIDS

read -p "Kill these processes? (yes/no): " CONFIRM
if [[ "$CONFIRM" =~ ^(yes|y)$ ]]; then
    for PID in $PIDS; do
        sudo kill -9 $PID
    done
    echo "Processes killed"
fi
