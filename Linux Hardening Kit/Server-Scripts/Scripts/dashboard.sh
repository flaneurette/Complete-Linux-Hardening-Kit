#!/bin/bash

LOGFILE="/var/log/daily_overview.log"

# Empty the log file at the start
> "$LOGFILE"

# Colors for terminal
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

{
    echo -e "${GREEN}================ Daily Overview ======================${NC}"
    date

    echo -e "${GREEN}================ Who's here ==========================${NC}"
    who

    echo -e "${GREEN}================ Last Logins =========================${NC}"
    last -n 10

    echo -e "${RED}================ Failed Logins =======================${NC}"
    sudo lastb -n 5

    echo -e "${YELLOW}================ System Uptime =======================${NC}"
    uptime

    echo -e "${YELLOW}================ Memory Usage ========================${NC}"
    free -h

    echo -e "${YELLOW}================ Top CPU Processes ===================${NC}"
    ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -n 5
    echo -e "${RED}==== High CPU Processes (>50%) ====${NC}"
    ps -eo pid,cmd,%cpu --sort=-%cpu | awk '$3>50 {print}'

    echo -e "${YELLOW}================ Top Memory Processes ================${NC}"
    ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -n 5
    echo -e "${RED}==== High Memory Processes (>50%) ====${NC}"
    ps -eo pid,cmd,%mem --sort=-%mem | awk '$3>50 {print}'

    echo -e "${GREEN}================ File System Stats ===================${NC}"
    df -h

    echo -e "${RED}================ Recent System Errors ================${NC}"
    sudo journalctl -p 3 -n 20 --no-pager
    echo -e "${RED}================ Kernel Errors =======================${NC}"
    dmesg --level=err | tail -n 20

    echo -e "${BLUE}================ Updates =============================${NC}"

    if [ -t 0 ]; then
        read -p "Update system? (y/n) " upd
    else
        upd="n"
    fi

    case $upd in
        y)
            echo -e "${BLUE}Updating system...${NC}"
            sudo apt-get update
            sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
            sudo apt-get autoremove -y
            ;;
        n)
            echo -e "${GREEN}Skipping update.${NC}"
            ;;
    esac

    echo -e "${BLUE}================ Done for today. =====================${NC}"

} | tee -a "$LOGFILE"
