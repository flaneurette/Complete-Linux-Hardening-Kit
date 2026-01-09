#!/bin/bash
echo "=== Zombie Processes ==="

ZOMBIES=$(ps aux | awk '$8=="Z" {print $0}')

if [ -z "$ZOMBIES" ]; then
    echo "No zombie processes found"
else
    echo "$ZOMBIES"
    echo -e "\nTo kill zombies, kill their parent process (PPID)"
fi
