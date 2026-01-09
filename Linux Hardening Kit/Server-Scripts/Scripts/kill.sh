#!/bin/bash

echo "=== ALL RUNNING PROCESSES ==="
echo "PID | PPID | USER | CPU% | MEM% | COMMAND"
echo "------------------------------------------------"

ps -eo pid,ppid,user,%cpu,%mem,comm --sort=-%cpu | head -50

echo "------------------------------------------------"
 
read -p "Enter process name to kill: " PROCESS

PIDS=$(pgrep -f "$PROCESS")

if [ -z "$PIDS" ]; then
    echo "No processes found matching '$PROCESS'"
    exit 0
fi

echo "Found processes:"
ps -fp $PIDS

read -p "Kill these processes? (yes/no): " CONFIRM
if [ "$CONFIRM" == "yes" ]; then
    pkill -f "$PROCESS"
    echo "Processes killed"
fi
