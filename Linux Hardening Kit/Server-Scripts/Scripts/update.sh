#!/bin/bash
apt update
apt upgrade -y
apt autoremove -y
echo "System updated on $(date)" >> /var/log/system-updates.log
