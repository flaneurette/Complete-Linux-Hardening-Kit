### DNS / DNSSEC Testing from Linux CLI

#### Install tools
```bash
sudo apt install dnsutils ldnsutils
```

#### Whois

```bash
whois example.com
```

### DNSSEC

#### Basic DNSSEC check
```bash
dig +dnssec example.com
```

Look for:
```
flags: qr rd ra ad
```

`ad` = DNSSEC validated.


#### Full DNSSEC records
```bash
dig +dnssec +multi example.com
```


#### DNSSEC validation
```bash
delv example.com
```

Expected:
```
; fully validated
```

#### DNSSEC failure test
```bash
dig dnssec-failed.org
```

Expected:
```
SERVFAIL
```

#### Trace DNSSEC chain
```bash
dig +trace +dnssec example.com
```


#### DNSSEC verification
```bash
drill -S example.com
```

#### Unbound DNSSEC check
```bash
unbound-host -D example.com
```

Output example:
```
example.com has address 93.184.216.34 (secure)
```

### Mail DNS checks

#### MX records
```bash
dig MX example.com
```

#### SPF record
```bash
dig TXT example.com
```

Look for:
```
v=spf1
```

#### DMARC
```bash
dig TXT _dmarc.example.com
```

#### DKIM
```bash
dig TXT selector._domainkey.example.com
```

### Other useful DNS queries

#### A record
```bash
dig A example.com
```

#### AAAA record
```bash
dig AAAA example.com
```

#### NS records
```bash
dig NS example.com
```

#### SOA
```bash
dig SOA example.com
```

### Full DNS lookup
```bash
dig example.com ANY
```

### Host command
```bash
host example.com
```

### DNS trace
```bash
dig +trace example.com
```

### Advanced DNSSEC analysis

#### Install DNSViz
```bash
pip install dnsviz
```

#### Probe domain
```bash
dnsviz probe example.com
```

#### Generate analysis graph
```bash
dnsviz graph example.com
```