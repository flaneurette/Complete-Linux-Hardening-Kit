#!/bin/bash
set -e

iptables-save > /etc/iptables/rules.v4.bak.firewall
ip6tables-save > /etc/iptables/rules.v6.bak.firewall

iptables-save > /etc/iptables/rules.v4
ip6tables-save > /etc/iptables/rules.v6

echo "Saved all iptables!"