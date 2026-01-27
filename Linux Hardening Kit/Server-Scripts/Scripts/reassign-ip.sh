#!/bin/bash
# sudo chmod +x reassign-ip.sh
# Reassign a new master IP, revokes the old one.
# This is useful, in case your(dynamic) IP changes
# To find the chain name: sudo iptables -L -n -v --line-numbers
# To find IP: sudo iptables -L -n -v --line-numbers | grep 100.2.3.4
# Notice: this script removes UFW.
# Notice: line prevents script from running suddenly. You MUST manually remove/uncomment this line:
exit 1

# Root check.
if [ "$EUID" -ne 0 ]; then
  echo "Run as root"
  exit 1
fi

# Edit these before running.

# To find the chain name: sudo iptables -L -n -v --line-numbers
CHAIN="ufw-user-input" # important, must match!
# Old IP to revoke access
OLD_IP="100.2.3.4"
# New IP
NEW_IP="101.2.6.7"

# Ports the NEW IP is allowed to connect to:
PORTS_TCP=(22 80 443 143 465 587 993 995 8080 8443)
PORTS_UDP=(8080 8443)

# Install netfilter-persistent (removes UFW!)
# sudo apt update
sudo apt install netfilter-persistent

# Delete old rules
for p in "${PORTS_TCP[@]}"; do
  sudo iptables -D $CHAIN -s $OLD_IP -p tcp --dport $p -j ACCEPT 2>/dev/null
done
for p in "${PORTS_UDP[@]}"; do
  sudo iptables -D $CHAIN -s $OLD_IP -p udp --dport $p -j ACCEPT 2>/dev/null
done

# Add new rules to INPUT chain. (recommended)
for p in "${PORTS_TCP[@]}"; do
  sudo iptables -A INPUT -s $NEW_IP -p tcp --dport $p -j ACCEPT
done
for p in "${PORTS_UDP[@]}"; do
  sudo iptables -A INPUT -s $NEW_IP -p udp --dport $p -j ACCEPT
done

sudo netfilter-persistent save
echo "Firewall rules updated successfully."
