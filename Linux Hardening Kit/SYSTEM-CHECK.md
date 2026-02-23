
###  VPS Security

Have at least these installed for much more security:

```
sudo apt install -y unattended-upgrades needrestart debsums aide auditd lynis fail2ban apparmor ssh-audit
```

Every once in a while review manually installed packages:

```
aptitude search '~i!~M' | grep -v "^i A"
```

Then clean the VPS to lessen attack landscape:

```
sudo apt remove eatmydata telnet inetutils-telnet swaks webalizer bpfcc-tools bpftrace strace trace-cmd apport snapd modemmanager tnftp procmail rmail ruby-net-telnet arp-scan xclip sosreport lxd-agent-loader lxd-installer multipath-tools
```

Then if Ubuntu:

```
apt remove ubuntu-kernel-accessories
```

The above prevent an upgrade to automatically install `bpfcc-tools`  again.

Then:

```
apt autoremove
```

Then run Lynis to get a fresh score:

```
sudo lynis audit system
```

Tools that are frequently abused in post-exploitation:

```
sslsniff-bpfcc is particularly concerning. This is an eBPF-based SSL/TLS sniffer that can intercept encrypted traffic in plaintext from within the host. It should almost never be on a production server.
ttysnoop-bpfcc can attach to TTY sessions and record everything typed by other users, including root. This is a surveillance/credential-harvesting tool.
sofdsnoop-bpfcc sniffs file descriptors passed over Unix sockets, which can expose sensitive IPC data.
bashreadline-bpfcc and bashreadline.bt hook into readline and capture everything typed in bash shells system-wide, including passwords typed at prompts.
opensnoop-bpfcc / opensnoop.bt trace every file open call system-wide, useful for discovering secret file paths.
execsnoop.bt traces every process execution system-wide. Fine for debugging, dangerous if an attacker uses it to watch for privileged operations.
```

The entire bpfcc / bpftrace suite is a risk surface

These are BPF/eBPF observability tools (from the BCC toolkit and bpftrace). Individually they are legitimate, but as a group they represent a powerful in-kernel monitoring and introspection framework. 
If an attacker gains any foothold, these tools give them deep visibility into the entire system with minimal noise. Consider whether all of them need to be present on a production machine.

Underrated risks that many sysadmins ignore you might want to consider:

```
procmail is an old mail processing tool with a long history of vulnerabilities and privilege escalation bugs. It runs setuid on many systems. Unless you specifically need it for mail filtering, remove it.
rmail is a legacy UUCP mail relay. Almost certainly not needed, and it has a history of exploitability.
webalizer is an old web log analyzer with known vulnerabilities. If it is processing untrusted log data, it can be exploited.
ModemManager has no obvious reason to be on a server. It increases attack surface unnecessarily.
usb_modeswitch and usb_modeswitch_dispatcher deal with USB device switching. On a headless server or VPS this is almost certainly not needed and represents unnecessary attack surface.
dhcpcd is a DHCP client daemon. On a server with static IPs, this should not be running. DHCP responses are unauthenticated and a rogue DHCP server on your network can push malicious routes or DNS servers.
pollinate contacts an entropy server (Ubuntu's by default) to seed /dev/random at boot. This is a phone-home behavior that some consider a risk in high-security environments.
vmhgfs-fuse and vmware-vmblock-fuse are VMware guest tools. If this is a VMware VM, these are expected, but they do represent a shared filesystem interface between host and guest that has had vulnerabilities historically.
```

---
