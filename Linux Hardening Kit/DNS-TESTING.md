### DNS / DNSSEC Testing from Linux CLI

#### Install tools
```
sudo apt install dnsutils ldnsutils dnsviz torsocks
```

#### Whois

```
whois example.com
```

> NOTE: if you restrict OUTPUT in iptables (very good choice) you might
want to whitelist port 43 for whois:

> iptables -A OUTPUT -p tcp --dport 43 -j ACCEPT

Somewhat safer:

```
whois -h whois.verisign-grs.com example.com
```

Better:
```
sudo systemctl start tor
torsocks whois example.com
sudo systemctl stop tor
```

### DNSSEC

#### Basic DNSSEC check
```
dig +dnssec example.com
```

Look for:
```
flags: qr rd ra ad
```

`ad` = DNSSEC validated.

#### Full DNSSEC records
```
dig +dnssec +multi example.com
```

#### DNSSEC validation
```
delv example.com
```

Expected:
```
; fully validated
```

#### DNSSEC failure test
```
dig dnssec-failed.org
```

Expected:
```
SERVFAIL
```

#### Trace DNSSEC chain
```
dig +trace +dnssec example.com
```

#### DNSSEC verification
```
drill -S example.com
```

#### Unbound DNSSEC check
```
unbound-host -D example.com
```

Output example:
```
example.com has address 93.184.216.34 (secure)
```

### Mail DNS checks

#### MX records
```
dig MX example.com
```

#### SPF record
```
dig TXT example.com
```

Look for:
```
v=spf1
```

#### DMARC
```
dig TXT _dmarc.example.com
```

#### DKIM
```
dig TXT selector._domainkey.example.com
```

### Other useful DNS queries

#### A record
```
dig A example.com
```

#### AAAA record
```
dig AAAA example.com
```

#### NS records
```
dig NS example.com
```

#### SOA
```
dig SOA example.com
```

### Full DNS lookup
```
dig example.com ANY
```

### Host command
```
host example.com
```

### DNS trace
```
dig +trace example.com
```

### Advanced DNSSEC analysis

#### Probe domain
```
dnsviz probe example.com
```

#### Generate analysis graph
```
dnsviz graph example.com
```