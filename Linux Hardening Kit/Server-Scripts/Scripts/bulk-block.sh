#!/bin/bash
# Block persistent attackers using iptables
# Requires root

# --- Config ---

CHAIN="persistent-attackers"

BLOCKLIST=(
    "64.226.95.181"
    "95.214.55.246"
    "92.63.197.66"
    "185.242.226.42"
    "185.242.226.43"
    "185.242.226.44"
    "45.252.250.198"
    "185.91.127.107"
    "204.76.203.219"
    "78.128.114.86"
)

SUBNETS=(
    "45.142.193.0/24"
    "79.124.58.0/24"
    "79.124.62.0/24"
    "216.180.246.0/24"
    "185.242.226.0/24"
    "185.156.73.0/24"
)

# --- Root check ---
if [ "$EUID" -ne 0 ]; then
  echo "Run as root"
  exit 1
fi

# --- Create chain if it doesn't exist ---
if ! iptables -L $CHAIN -n >/dev/null 2>&1; then
    echo "Creating chain $CHAIN..."
    iptables -N $CHAIN
else
    echo "Chain $CHAIN already exists"
fi

# --- Ensure INPUT jumps to our chain ---
if ! iptables -C INPUT -j $CHAIN >/dev/null 2>&1; then
    iptables -I INPUT -j $CHAIN
    echo "Added jump from INPUT to $CHAIN"
fi

# --- Block individual IPs ---
echo "Blocking individual IPs..."
for ip in "${BLOCKLIST[@]}"; do
    if ! iptables -C $CHAIN -s "$ip" -j DROP >/dev/null 2>&1; then
        iptables -A $CHAIN -s "$ip" -j DROP
        echo "Blocked $ip"
    fi
done

# --- Block subnets ---
echo "Blocking subnets..."
for subnet in "${SUBNETS[@]}"; do
    if ! iptables -C $CHAIN -s "$subnet" -j DROP >/dev/null 2>&1; then
        iptables -A $CHAIN -s "$subnet" -j DROP
        echo "Blocked subnet $subnet"
    fi
done

# --- Save rules persistently ---
if command -v netfilter-persistent >/dev/null 2>&1; then
    netfilter-persistent save
    echo "Saved iptables rules persistently"
else
    echo "Install netfilter-persistent to save rules across reboots"
fi

# --- Summary ---
echo "Done! Current block count:"
iptables -L $CHAIN -n | grep -c DROP
