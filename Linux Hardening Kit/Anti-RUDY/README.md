# Defending Against R.U.D.Y. Attacks in Apache

## What is a R.U.D.Y. Attack?

R.U.D.Y. is a slow POST attack that exhausts web server resources without requiring high bandwidth or sophisticated tools.

### How it works:

1. The attacker's tool scans your application for forms with POST endpoints
2. It initiates an HTTP POST request with a large `Content-Length` header (claiming it will send megabytes of data)
3. The actual data is sent extremely slowly - often just 1 byte every 10 seconds
4. The server waits patiently for the data, keeping the connection open and tying up server threads/processes
5. With enough simultaneous slow connections, legitimate users cannot connect

Key insight: R.U.D.Y. exploits server politeness, not a vulnerability. The server is designed to wait for slow clients (mobile users, poor connections), and attackers abuse this behavior.

---

## Why Apache is Vulnerable

Apache's traditional prefork MPM (Multi-Processing Module) allocates one process per connection. Each slow POST request:

- Consumes a worker process
- Holds it hostage until the request completes or times out
- With default timeouts of 300+ seconds, a few dozen slow connections can exhaust your server capacity

Result: Legitimate users see "503 Service Unavailable" or cannot connect at all.

---

## Defense Strategy

### 1. Enable `mod_reqtimeout` (Primary Defense)

Apache's built-in `mod_reqtimeout` module enforces minimum data rates and timeouts:

```apache
<IfModule reqtimeout_module>
    # Headers must arrive within 20-40 seconds at minimum 500 bytes/sec
    # Body data must arrive at minimum 500 bytes/sec, starting after 20 seconds
    RequestReadTimeout header=20-40,MinRate=500 body=20,MinRate=500
</IfModule>
```

What this does:
- Drops connections that send headers too slowly
- Terminates POST requests sending body data slower than 500 bytes/second
- R.U.D.Y. attacks sending 1 byte per 10 seconds are immediately blocked

Enable the module:
```bash
sudo a2enmod reqtimeout
sudo systemctl restart apache2
```

---

### 2. Limit POST Body Size

Prevent attackers from claiming they'll send gigabytes of data:

```apache
# Limit POST body to 10 MB (adjust based on your needs)
LimitRequestBody 10485760
```

If your application doesn't accept file uploads, set this much lower:

```apache
# For forms with text only
LimitRequestBody 1048576  # 1 MB
```

Place this in:
- `/etc/apache2/apache2.conf` for global application
- Inside `<VirtualHost>` blocks for per-site limits
- Inside `<Directory>` or `<Location>` blocks for specific paths

---

### 3. Tune KeepAlive Settings

Prevent connections from staying idle too long:

```apache
KeepAlive On
MaxKeepAliveRequests 100
KeepAliveTimeout 5
```

Explanation:
- `KeepAlive On` - allows connection reuse (good for performance)
- `MaxKeepAliveRequests 100` - limits requests per connection
- `KeepAliveTimeout 5` - closes idle connections after 5 seconds

This prevents attackers from opening connections and leaving them idle.

---

### 4. Switch to Event MPM (Recommended)

The traditional prefork MPM blocks one entire process per connection. The event MPM handles slow connections asynchronously, dramatically improving resistance to slow attacks.

Check your current MPM:
```bash
apachectl -V | grep MPM
```

Switch to event MPM:
```bash
sudo a2dismod mpm_prefork
sudo a2enmod mpm_event
sudo systemctl restart apache2
```

Note: Ensure your PHP setup is compatible. Use `php-fpm` instead of `mod_php` with event MPM:

```bash
sudo a2dismod php7.4  # or your PHP version
sudo a2enmod proxy_fcgi setenvif
sudo a2enconf php7.4-fpm  # or your PHP version
sudo systemctl restart apache2
```

---

### 5. Rate Limiting with mod_qos (Optional)

For additional protection, install `mod_qos` to limit requests per IP:

```bash
sudo apt install libapache2-mod-qos
sudo a2enmod qos
```

Basic configuration:

```apache
<IfModule qos_module>
    # Maximum 20 concurrent connections per IP
    QS_SrvMaxConnPerIP 20
    
    # Minimum request rate: 150 bytes/sec
    QS_SrvMinDataRate 150
    
    # Maximum 50 requests per second per IP
    QS_SrvRequestRate 50
</IfModule>
```

---

### 6. Operating System Tuning (Optional)

Reduce TCP connection timeouts at the kernel level.

Edit `/etc/sysctl.conf`:

```bash
# Reduce FIN_WAIT timeout
net.ipv4.tcp_fin_timeout = 15

# Reduce keepalive probes
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.tcp_keepalive_intvl = 15

# Increase max connections
net.core.somaxconn = 4096
```

Apply changes:
```bash
sudo sysctl -p
```

---

## Complete Hardened Configuration Example

Here's a production-ready configuration snippet:

```apache
# /etc/apache2/conf-available/security-hardening.conf

# Connection management
KeepAlive On
MaxKeepAliveRequests 100
KeepAliveTimeout 5

# Timeout settings
Timeout 60

# Request size limits
LimitRequestBody 10485760
LimitRequestFields 100
LimitRequestFieldSize 8190
LimitRequestLine 8190

# Slow request protection
<IfModule reqtimeout_module>
    RequestReadTimeout header=20-40,MinRate=500 body=20,MinRate=500
</IfModule>

# Rate limiting (optional)
<IfModule qos_module>
    QS_SrvMaxConnPerIP 20
    QS_SrvMinDataRate 150
</IfModule>
```

Enable this configuration:
```bash
sudo a2enconf security-hardening
sudo systemctl reload apache2
```

---

## Testing Your Defenses

Test if your server drops slow connections:

```bash
# This should be rejected quickly by your server
curl -X POST \
  -H "Content-Length: 1000000" \
  --limit-rate 10 \
  http://yoursite.com/contact-form
```

If properly configured, the connection should drop within ~30 seconds instead of hanging for minutes.

---

## Using Cloudflare as Additional Protection

Cloudflare automatically mitigates R.U.D.Y. attacks by:

- Buffering POST requests at their edge servers
- Enforcing minimum upload speeds
- Only forwarding complete requests to your origin server

This is complementary, not required. The Apache configuration above is sufficient on its own, but Cloudflare adds an additional layer of protection and reduces attack traffic reaching your server.

---

## Defense Checklist

| Protection Layer | Implementation | Effectiveness |
|------------------|----------------|---------------|
| Minimum data rate | `RequestReadTimeout` |  Primary defense |
| Body size limits | `LimitRequestBody` |  Prevents resource exhaustion |
| Connection timeouts | `KeepAliveTimeout` |  Reduces idle connections |
| Async processing | Event MPM |  Massive scalability boost |
| Rate limiting | `mod_qos` |  Blocks aggressive attackers |
| Edge protection | Cloudflare |  Stops attacks before they reach you |

---

## Monitoring and Alerts

Watch for R.U.D.Y. attacks in your logs:

```bash
# Look for slow POST requests
sudo tail -f /var/log/apache2/access.log | grep POST

# Monitor active connections
sudo netstat -an | grep :80 | wc -l

# Check for timeout errors
sudo grep "Timeout" /var/log/apache2/error.log
```

Set up monitoring alerts when:
- Active connections exceed 80% of MaxClients/MaxRequestWorkers
- Request completion times suddenly increase
- CPU iowait percentage rises abnormally

---

## Summary

R.U.D.Y. attacks are easily defeated with proper Apache configuration:

1. Enable `mod_reqtimeout` with minimum data rates (essential)
2. Limit request body sizes appropriate to your application
3. Use short KeepAlive timeouts to prevent idle connection abuse
4. Switch to event MPM for better handling of slow connections
5. Optional: Add rate limiting and edge protection for defense in depth

The key principle: don't let slow clients monopolize your server resources. With these configurations, your Apache server will automatically drop connections that are too slow to be legitimate users, while still accommodating users with reasonable connection speeds.

---

Need help? Test your configuration thoroughly in a staging environment before deploying to production. Monitor your logs for false positives (legitimate slow clients being blocked) and adjust thresholds as needed.
