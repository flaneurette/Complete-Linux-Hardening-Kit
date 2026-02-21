# DNS privacy: Unbound.

For good DNS privacy, use `Unbound`

Running your own recursive resolver also means DNS queries are no longer logged by Cloudflare or Google.  You own the full resolution chain. No third party can silently return wrong answers, inject responses, 
or cut off access to certain zones like Spamhaus did with public resolvers. Cache poisoning risk is lower with a modern recursive resolver running DNSSEC validation, which unbound does by default. 
Public resolvers also do this but you are trusting them to do it correctly. No dependency on a third party whose interests may not align with yours and who can be a single point of failure or surveillance. 
For a mail server handling real traffic that is a good improvement.

More private, more resilient, slightly more responsibility on your end to keep it maintained.
  
---

### Install Unbound

```
sudo apt install unbound
```

---

### Configure Unbound

Edit `/etc/unbound/unbound.conf`. On Debian the default file uses `include-toplevel` to pull
in conf.d files. Add the server block:

```
include-toplevel: "/etc/unbound/unbound.conf.d/*.conf"
server:
    interface: 127.0.0.1
    access-control: 127.0.0.0/8 allow
    hide-identity: yes
    hide-version: yes
    qname-minimisation: yes
```

Check for any conflicting files in the conf.d directory:

```
ls /etc/unbound/unbound.conf.d/
```

Validate the config:

```
sudo unbound-checkconf
```

---

### Start Unbound

```
sudo systemctl enable --now unbound
```

Verify it started cleanly:

```
sudo systemctl status unbound
sudo journalctl -u unbound -n 50
```

Check what is listening on port 53:

```
sudo ss -tulpn | grep :53
```

You should see unbound on 127.0.0.1:53. You may also see systemd-resolved on 127.0.0.53 and
127.0.0.54 - those are separate addresses and will not conflict.

---

### Fix iptables Rules

If your server has a restrictive iptables INPUT policy, DNS traffic to unbound on loopback
will be blocked. This manifests as dig timing out even though unbound is running.

Check if unbound is receiving any queries:

```
sudo unbound-control stats | head -5
```

If `thread0.num.queries=0` then traffic is being blocked before reaching unbound.

Add INPUT rules for both UDP and TCP on port 53:

```
# UDP first:
sudo iptables -I INPUT -i lo -p udp --dport 53 -j ACCEPT
sudo iptables -I OUTPUT -p udp --dport 53 -j ACCEPT

# Optional TCP:
sudo iptables -I INPUT -i lo -p tcp --dport 53 -j ACCEPT
sudo iptables -I OUTPUT -p tcp --dport 53 -j ACCEPT
```

> Note: UDP is required for standard DNS queries. TCP is required for large responses and DNSSEC. Sometimes both are needed. I would suggest trying `udp` first, and skip tcp.

---

### Test Unbound

Basic resolution test:

```
dig @127.0.0.1 google.com
```

Spamhaus test lookup (should return 127.0.0.2):

```
dig @127.0.0.1 2.0.0.127.zen.spamhaus.org
```

If the Spamhaus query returns 127.0.0.2 your RBL lookups are working correctly.

---

### Update resolv.conf

Point the system resolver at your local unbound instance:

```
nameserver 127.0.0.1
```

If systemd-networkd or dhclient overwrites resolv.conf, pin it:

```
sudo chattr +i /etc/resolv.conf
```

---

### Restart Postfix

```
sudo systemctl restart postfix
```

Postfix will now use your local resolver for all DNS lookups including RBL queries, DMARC
lookups, and sender address verification.

---

### Verify

Watch the mail log for a few minutes after restarting:

```
sudo journalctl -u postfix -f
```

---

### Notes

- systemd-resolved running on 127.0.0.53 will not conflict with unbound on 127.0.0.1
- The DAEMON_OPTS environment variable warning from unbound.service is harmless
- qname-minimisation improves privacy by sending minimal query data to upstream nameservers
- Running your own recursive resolver also means DNS queries are no longer logged by
  Cloudflare or Google