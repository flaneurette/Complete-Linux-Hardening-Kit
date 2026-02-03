# Reassign a new master IP, revokes the old one.
# This is useful, in case your(dynamic) IP changes
# To find the chain name: sudo iptables -L -n -v --line-numbers
# To find IP: sudo iptables -L -n -v --line-numbers | grep 100.2.3.4
# Notice: line prevents script from running suddenly. You MUST manually remove/comment this line:
exit 1

# Root check.
if [ "$EUID" -ne 0 ]; then
  echo "Run as root"
  exit 1
fi

# Edit these before running.

# To find the chain name: sudo iptables -L -n -v --line-numbers
CHAIN="INPUT" # important, must match!

# Old private IP to revoke access
OLD_IP="1.2.3.4"
# New IP
NEW_IP="1.2.3.5"

# Server IP:
SERVER_IP="5.4.3.2.1"

# Ports the NEW IP is allowed to connect to:
PORTS_TCP=(22 80 443 110 143 465 587 993 995 8080 8443)
PORTS_UDP=(8080 8443)
# Drop for WAN
PORTS_TCPDROP=(22 110 143 465 587 993 995 8080 8443)

# Backup
sudo iptables-save > /etc/iptables/rules.v4.bak

# Delete old rules
for p in "${PORTS_TCP[@]}"; do
  sudo iptables -D $CHAIN -s $OLD_IP -p tcp --dport $p -j ACCEPT 2>/dev/null
done
for p in "${PORTS_UDP[@]}"; do
  sudo iptables -D $CHAIN -s $OLD_IP -p udp --dport $p -j ACCEPT 2>/dev/null
done

# Add new IP rules to INPUT chain. (recommended)
for p in "${PORTS_TCP[@]}"; do
  sudo iptables -A INPUT -s $NEW_IP -p tcp --dport $p -j ACCEPT
done
for p in "${PORTS_UDP[@]}"; do
  sudo iptables -A INPUT -s $NEW_IP -p udp --dport $p -j ACCEPT
done

# Add new SERVER rules to INPUT chain. (recommended)
for p in "${PORTS_TCP[@]}"; do
  sudo iptables -A INPUT -s $SERVER_IP -p tcp --dport $p -j ACCEPT
done
for p in "${PORTS_UDP[@]}"; do
  sudo iptables -A INPUT -s $SERVER_IP -p udp --dport $p -j ACCEPT
done

# drop for all others
for p in "${PORTS_TCPDROP[@]}"; do
  sudo iptables -A INPUT -p tcp --dport $p -j DROP
done
for p in "${PORTS_UDP[@]}"; do
  sudo iptables -A INPUT -p udp --dport $p -j DROP
done

# If you have tailscale:
sudo iptables -A INPUT -i tailscale0 -p tcp --dport 22 -j ACCEPT

# If you have a mailserver:
sudo iptables -A INPUT  -p tcp --dport 25 -j ACCEPT

# Allow web-access to all
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443  -j ACCEPT

iptables-save > /etc/iptables/rules.v4

echo "Firewall rules updated successfully."
