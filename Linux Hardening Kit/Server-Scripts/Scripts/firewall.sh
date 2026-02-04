#!/bin/bash

# Backup
sudo iptables-save > /etc/iptables/rules.v4.bak.firewall
sudo ip6tables-save > /etc/iptables/rules.v6.bak.firewall

# Save
sudo iptables-save > /etc/iptables/rules.v4
sudo ip6tables-save > /etc/iptables/rules.v6

echo "Saved all iptables!"