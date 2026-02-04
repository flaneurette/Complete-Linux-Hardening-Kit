#!/bin/bash

# Script to block an IP or CIDR. Requests an IP/CIDR.
# Must use iptables!

CHAIN="persistent-attacker"

read -p "Enter IP or CIDR to block: " BLOCK_IP

if [[ -z "$BLOCK_IP" ]]; then
    echo "No IP provided. Exiting."
    exit 1
fi

# Backup iptables
sudo iptables-save > /etc/iptables/rules.v4.bak.ipblocker
# if fault: iptables-restore < /etc/iptables/rules.v4.bak.ipblocker

# Check if chain exists
if ! iptables -L "$CHAIN" -n >/dev/null 2>&1; then
    echo "Creating chain: $CHAIN"
    iptables -N "$CHAIN"
else
    echo "Chain $CHAIN already exists"
fi

# Ensure chain is hooked into INPUT
if ! iptables -C INPUT -j "$CHAIN" >/dev/null 2>&1; then
    echo "Linking $CHAIN to INPUT"
    iptables -A INPUT -j "$CHAIN"
else
    echo "$CHAIN already linked to INPUT"
fi

# Check if IP is already blocked
if iptables -S "$CHAIN" | grep -q -- "-s $BLOCK_IP "; then
    echo "IP $BLOCK_IP is already blocked"
else
    echo "Blocking $BLOCK_IP"
    iptables -A "$CHAIN" -s "$BLOCK_IP" -j DROP
fi

sudo iptables-save > /etc/iptables/rules.v4

echo "Done."
