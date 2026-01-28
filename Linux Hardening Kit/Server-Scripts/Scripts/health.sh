#!/bin/bash
echo "================================"
echo "   SYSTEM HEALTH REPORT"
echo "   Generated: $(date)"
echo "================================"

echo -e "\n--- SYSTEM INFO ---"
echo "Hostname: $(hostname)"
echo "Uptime: $(uptime -p)"
echo "Kernel: $(uname -r)"

echo -e "\n--- CPU ---"
echo "Load Average: $(cat /proc/loadavg | awk '{print $1, $2, $3}')"
echo "CPU Usage: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}')%"

echo -e "\n--- MEMORY ---"
free -h | awk 'NR==2{printf "Used: %s / %s (%.2f%%)\n", $3, $2, $3*100/$2}'

echo -e "\n--- DISK ---"
df -h | grep -vE 'tmpfs|loop' | awk 'NR>1{printf "%s: %s / %s (%s)\n", $6, $3, $2, $5}'

echo -e "\n--- NETWORK ---"
ip -4 addr show | grep inet | awk '{print $NF, $2}'

echo -e "\n--- TOP PROCESSES (CPU) ---"
ps aux --sort=-%cpu | head -6 | awk 'NR>1{printf "%s: %s%% CPU\n", $11, $3}'

echo -e "\n--- TOP PROCESSES (MEM) ---"
ps aux --sort=-%mem | head -6 | awk 'NR>1{printf "%s: %s%% MEM\n", $11, $4}'

echo -e "\n--- FAILED SERVICES ---"
systemctl --failed
