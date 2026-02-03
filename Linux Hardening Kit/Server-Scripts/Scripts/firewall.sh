#!/bin/bash

 (broken)
sudo iptables-save > /etc/iptables/rules.v4
sudo ip6tables-save > /etc/iptables/rules.v6

echo "Saved all iptables!"