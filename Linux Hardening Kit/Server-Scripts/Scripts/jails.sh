#!/bin/bash

# Colors
GREEN="\e[32m"
RED="\e[31m"
RESET="\e[0m"

echo -e "=== Fail2Ban Jail Summary ===\n"

# Get all jails
jails=$(sudo fail2ban-client status | grep 'Jail list' | cut -d: -f2 | tr ',' ' ')

# Print header
printf "%-20s %-10s %-60s\n" "Jail" "Banned" "IPs"
echo "--------------------------------------------------------------------------------"

for jail in $jails; do
    jail=$(echo $jail | xargs)
    count=$(sudo fail2ban-client status "$jail" | grep 'Currently banned' | awk '{print $4}')
    ips=$(sudo fail2ban-client status "$jail" | grep 'Banned IP list' | cut -d: -f2 | xargs)

    # Colorize count
    if [ "$count" -gt 0 ]; then
        count_colored="${RED}${count}${RESET}"
    else
        count_colored="${GREEN}${count}${RESET}"
        ips="None"
    fi

    # Use -e in echo to interpret escape sequences
    echo -e "$(printf "%-20s %-10s %-60s" "$jail" "$count_colored" "$ips")"
done
