#!/bin/bash
read -p "Enter process name to search: " SEARCH

echo "=== Processes matching '$SEARCH' ==="

ps aux | grep -i "$SEARCH" | grep -v grep | \
    awk '{printf "PID: %-8s User: %-10s CPU: %-6s MEM: %-6s CMD: %s\n", 
          $2, $1, $3"%", $4"%", $11}'

# Alternative using pgrep
echo -e "\n=== Using pgrep ==="
pgrep -a "$SEARCH"
