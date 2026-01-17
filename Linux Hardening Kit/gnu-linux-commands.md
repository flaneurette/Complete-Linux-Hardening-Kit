# GNU Linux Commands Reference Guide

---

## Most Commonly Used Commands

### File and Directory Operations

```bash
# List files
ls                    # List files in current directory
ls -la                # List all files with details (including hidden)
ls -lh                # List with human-readable sizes
ls -lt                # List sorted by modification time

# Navigate directories
cd /path/to/dir       # Change directory
cd ~                  # Go to home directory
cd -                  # Go to previous directory
pwd                   # Print working directory

# Create and remove
mkdir directory_name  # Create directory
mkdir -p path/to/dir  # Create nested directories
rm file.txt           # Remove file
rm -r directory       # Remove directory recursively
rm -rf directory      # Force remove (dangerous!)
rmdir directory       # Remove empty directory

# Copy and move
cp source dest        # Copy file
cp -r source dest     # Copy directory recursively
mv source dest        # Move or rename
mv *.txt backup/      # Move all .txt files

# View files
cat file.txt          # Display entire file
less file.txt         # View file page by page (q to quit)
head file.txt         # Show first 10 lines
head -n 20 file.txt   # Show first 20 lines
tail file.txt         # Show last 10 lines
tail -f file.txt      # Follow file in real-time (logs)

# Search in files
grep "pattern" file   # Search for pattern in file
grep -r "pattern" .   # Search recursively in directory
grep -i "pattern" f   # Case-insensitive search
grep -v "pattern" f   # Invert match (exclude pattern)

# Find files
find . -name "*.txt"  # Find files by name
find . -type f -size +100M  # Find files larger than 100MB
find . -mtime -7      # Find files modified in last 7 days
locate filename       # Quick file search (uses database)
```

### File Permissions

```bash
# View permissions
ls -l file.txt        # Shows: -rw-r--r-- owner group

# Change permissions
chmod 755 file.sh     # rwxr-xr-x (owner:all, group:rx, other:rx)
chmod +x script.sh    # Add execute permission
chmod -w file.txt     # Remove write permission
chmod u+x file.sh     # Add execute for user only

# Change ownership
chown user:group file # Change owner and group
chown -R user dir/    # Change recursively
chgrp group file      # Change group only

# Permission numbers:
# 4 = read (r)
# 2 = write (w)
# 1 = execute (x)
# 7 = rwx, 6 = rw-, 5 = r-x, 4 = r--
```

### Process Management

```bash
# View processes
ps aux                # All processes
ps aux | grep nginx   # Find specific process
top                   # Real-time process viewer
htop                  # Better process viewer (if installed)
pgrep -a nginx        # Find process by name

# Kill processes
kill PID              # Terminate process
kill -9 PID           # Force kill
killall process_name  # Kill all instances
pkill process_name    # Kill by name

# Background processes
command &             # Run in background
jobs                  # List background jobs
fg %1                 # Bring job 1 to foreground
bg %1                 # Resume job 1 in background
nohup command &       # Run immune to hangups
```

### System Information

```bash
# System info
uname -a              # System information
hostname              # Computer name
uptime                # System uptime
date                  # Current date/time
cal                   # Calendar
whoami                # Current user
who                   # Logged in users

# Hardware info
lscpu                 # CPU information
lsmem                 # Memory information
lsblk                 # Block devices (disks)
lsusb                 # USB devices
lspci                 # PCI devices
free -h               # Memory usage
df -h                 # Disk space usage
du -sh directory      # Directory size
du -h --max-depth=1   # Size of subdirectories
```

### Network Commands

```bash
# Network info
ip addr               # IP addresses
ip a                  # Short form
ifconfig              # Network interfaces (older)
hostname -I           # Local IP address

# Connectivity
ping google.com       # Test connectivity
ping -c 4 google.com  # Ping 4 times only
traceroute google.com # Trace route to host
mtr google.com        # Combined ping/traceroute

# Network testing
curl https://site.com # Download/view webpage
wget https://file.com # Download file
netstat -tulpn        # Show listening ports
ss -tulpn             # Modern netstat alternative
nmap localhost        # Port scan

# DNS
nslookup google.com   # DNS lookup
dig google.com        # Detailed DNS info
host google.com       # Simple DNS lookup
```

### Package Management

**Debian/Ubuntu (apt)**
```bash
sudo apt update           # Update package list
sudo apt upgrade          # Upgrade packages
sudo apt install package  # Install package
sudo apt remove package   # Remove package
sudo apt search package   # Search for package
sudo apt autoremove       # Remove unused packages
```

**RedHat/CentOS (yum/dnf)**
```bash
sudo yum update           # Update packages
sudo yum install package  # Install package
sudo yum remove package   # Remove package
sudo yum search package   # Search for package
```

### User Management

```bash
# User operations
sudo useradd username     # Create user
sudo userdel username     # Delete user
sudo passwd username      # Change password
sudo usermod -aG group u  # Add user to group
id username               # Show user info
groups username           # Show user groups
su - username             # Switch user
sudo command              # Run as root
```

### Archive and Compression

```bash
# Tar archives
tar -czf archive.tar.gz dir/   # Create compressed archive
tar -xzf archive.tar.gz        # Extract archive
tar -tzf archive.tar.gz        # List contents

# Zip
zip -r archive.zip dir/        # Create zip
unzip archive.zip              # Extract zip
unzip -l archive.zip           # List contents

# Other
gzip file.txt                  # Compress file
gunzip file.txt.gz             # Decompress
bzip2 file.txt                 # Better compression
bunzip2 file.txt.bz2           # Decompress bzip2
```

### Text Processing

```bash
# Sorting and filtering
sort file.txt             # Sort lines
sort -r file.txt          # Reverse sort
uniq file.txt             # Remove duplicates
wc file.txt               # Word/line/byte count
wc -l file.txt            # Count lines only

# Text manipulation
cut -d: -f1 /etc/passwd   # Extract column
awk '{print $1}' file     # Print first field
sed 's/old/new/g' file    # Replace text
tr 'a-z' 'A-Z' < file     # Translate characters

# Comparison
diff file1 file2          # Compare files
cmp file1 file2           # Binary comparison
comm file1 file2          # Compare sorted files
```

---

## Emergency & Recovery Commands

### System Not Booting

```bash
# Boot into recovery mode
# At GRUB menu, select "Advanced options"  "Recovery mode"

# Remount root filesystem as read-write
mount -o remount,rw /

# Fix filesystem errors
fsck /dev/sda1            # Check and repair filesystem
fsck -y /dev/sda1         # Auto-yes to repairs
e2fsck -f /dev/sda1       # Force check ext2/3/4

# Reinstall GRUB bootloader
grub-install /dev/sda
update-grub

# Check disk health
smartctl -a /dev/sda      # SMART status
badblocks -v /dev/sda1    # Check for bad blocks
```

### Disk Full Emergency

```bash
# Find what's using space
df -h                     # Overview of disk usage
du -h / | sort -rh | head -20  # Top 20 space users
du -sh /*                 # Size of root directories
ncdu /                    # Interactive disk usage (if installed)

# Quick cleanup
# Clear package cache
sudo apt clean            # Debian/Ubuntu
sudo yum clean all        # RedHat/CentOS

# Clear old logs
sudo journalctl --vacuum-time=3d  # Keep only 3 days
sudo find /var/log -type f -name "*.log" -mtime +30 -delete

# Clear temp files
sudo rm -rf /tmp/*
sudo rm -rf /var/tmp/*

# Find and remove large files
find / -type f -size +1G 2>/dev/null
find /var/log -type f -size +100M -delete

# Clear user cache
rm -rf ~/.cache/*
```

### System Frozen/Unresponsive

```bash
# Magic SysRq keys (when system is frozen)
# Hold Alt + SysRq (Print Screen), then press these in order:
# R - Take control from X
# E - Send SIGTERM to all processes
# I - Send SIGKILL to all processes
# S - Sync disks
# U - Unmount and remount read-only
# B - Reboot

# From another terminal (SSH or TTY)
# Switch to another TTY: Ctrl+Alt+F2 (F1-F6)

# Find and kill problematic process
top                       # Find high CPU/memory process
ps aux | grep process
kill -9 PID

# Find and kill all user processes
killall -u username

# System load check
uptime                    # Check load average
w                         # Who's logged in and what they're doing

# Memory pressure
free -h                   # Check memory
sudo sync                 # Flush filesystem buffers
echo 3 > /proc/sys/vm/drop_caches  # Clear cache (as root)
```

### Forgot Root Password

```bash
# Method 1: Single User Mode
# At GRUB, press 'e' to edit boot parameters
# Find line starting with 'linux', add at end:
init=/bin/bash

# Boot, then:
mount -o remount,rw /
passwd root
sync
reboot -f

# Method 2: Boot from Live USB
# Mount the system partition
mkdir /mnt/system
mount /dev/sda1 /mnt/system
chroot /mnt/system
passwd root
exit
umount /mnt/system
reboot
```

### Network Down Emergency

```bash
# Check network interface status
ip link show              # List interfaces
ip addr show              # Show IP addresses

# Bring interface up/down
sudo ip link set eth0 down
sudo ip link set eth0 up

# Restart networking
sudo systemctl restart networking        # Debian/Ubuntu
sudo systemctl restart NetworkManager    # Most distros
sudo service network restart             # Older systems

# Manual IP configuration
sudo ip addr add 192.168.1.100/24 dev eth0
sudo ip route add default via 192.168.1.1

# Check DNS
cat /etc/resolv.conf      # DNS servers
ping 8.8.8.8              # Test without DNS
ping google.com           # Test with DNS

# Reset network settings
sudo ip addr flush dev eth0
sudo dhclient eth0        # Request new DHCP lease

# Check for conflicts
sudo arp-scan --interface=eth0 --localnet
```

### Backup Critical Data (Emergency)

```bash
# Quick backup to external drive
# Mount external drive first
lsblk                     # Find device name
sudo mount /dev/sdb1 /mnt

# Backup home directory
sudo tar -czf /mnt/home-backup-$(date +%Y%m%d).tar.gz /home

# Backup specific directories
sudo rsync -av /home /etc /var /mnt/backup/

# Create disk image
sudo dd if=/dev/sda of=/mnt/disk-image.img bs=4M status=progress

# Backup entire system (exclude virtual filesystems)
sudo rsync -aAXv / --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found"} /mnt/backup/
```

### Process Consuming All Resources

```bash
# Identify the culprit
top                       # Press Shift+P for CPU, Shift+M for memory
ps aux --sort=-%cpu | head -10   # Top CPU users
ps aux --sort=-%mem | head -10   # Top memory users

# Detailed process info
pmap -x PID               # Memory map
lsof -p PID               # Open files
strace -p PID             # System calls (debug)

# Kill resource hog
kill PID                  # Graceful
kill -9 PID               # Force kill
killall -9 process_name   # Kill all instances

# Limit future resource usage
nice -n 19 command        # Run with low priority
renice -n 10 -p PID       # Change priority of running process

# Set resource limits
ulimit -a                 # View limits
ulimit -m 1000000         # Limit memory (KB)
ulimit -u 100             # Limit processes
```

---

## System Rescue Operations

### Rescue from Live USB/CD

```bash
# Boot from live USB, then:

# 1. Identify your system partition
lsblk
fdisk -l

# 2. Mount system
mkdir /mnt/system
mount /dev/sda1 /mnt/system       # Root partition
mount /dev/sda2 /mnt/system/boot  # Boot partition (if separate)

# 3. Mount critical filesystems
mount --bind /dev /mnt/system/dev
mount --bind /proc /mnt/system/proc
mount --bind /sys /mnt/system/sys
mount --bind /run /mnt/system/run

# 4. Chroot into your system
chroot /mnt/system /bin/bash

# Now you're in your system! You can:
# - Reset passwords
# - Fix GRUB
# - Repair packages
# - Edit config files
# - Reinstall kernel

# 5. Exit and cleanup
exit
umount /mnt/system/dev
umount /mnt/system/proc
umount /mnt/system/sys
umount /mnt/system/run
umount /mnt/system/boot
umount /mnt/system
reboot
```

### Fix Broken Package Manager

```bash
# Debian/Ubuntu
sudo apt --fix-broken install
sudo dpkg --configure -a
sudo apt update --fix-missing
sudo apt install -f

# If APT database is corrupted
sudo rm /var/lib/apt/lists/* -vf
sudo apt update

# Force reinstall package
sudo apt install --reinstall package

# RedHat/CentOS
sudo yum clean all
sudo yum check
sudo yum update
sudo rpm --rebuilddb
```

### Check System Logs for Errors

```bash
# View recent critical errors
journalctl -p err -b         # Errors from current boot
journalctl -p crit -b        # Critical errors
journalctl -xb               # Boot messages with explanation
journalctl -f                # Follow live logs

# Specific service logs
journalctl -u nginx.service
journalctl -u ssh.service --since "1 hour ago"

# Traditional logs
tail -f /var/log/syslog      # System log
tail -f /var/log/auth.log    # Authentication
tail -f /var/log/kern.log    # Kernel messages
dmesg | tail -50             # Kernel ring buffer

# Search for specific errors
grep -i error /var/log/syslog
grep -i fail /var/log/auth.log
```

### Security Emergency - Suspected Compromise

```bash
# 1. Disconnect from network immediately
sudo ip link set eth0 down

# 2. Check for unauthorized users
who
w
last                         # Recent logins
lastb                        # Failed login attempts

# 3. Check running processes
ps aux
top
pstree -p

# 4. Check network connections
netstat -tulpn
ss -tulpn
lsof -i                      # Files opened by network

# 5. Check scheduled tasks
crontab -l                   # User crontabs
sudo crontab -l              # Root crontab
ls -la /etc/cron.*           # System cron jobs
systemctl list-timers        # Systemd timers

# 6. Check for suspicious files
find / -type f -mtime -1     # Modified in last 24h
find /tmp -type f            # Files in /tmp
find / -name "*.sh" -mtime -7  # Recent scripts

# 7. Check authorized SSH keys
cat ~/.ssh/authorized_keys
sudo cat /root/.ssh/authorized_keys

# 8. Check sudoers
sudo cat /etc/sudoers
ls -la /etc/sudoers.d/

# 9. Audit installed packages (recent)
dpkg -l | grep $(date +%Y-%m-%d)  # Today's installs
rpm -qa --last | head -20         # Recent RPM installs

# 10. System file integrity check
sudo aide --check            # If AIDE is installed
```

### Service Won't Start

```bash
# Check service status
systemctl status service_name
journalctl -u service_name -n 50

# View service configuration
systemctl cat service_name

# Test service configuration
service_name -t              # Test config (nginx, apache)
configtest                   # Some services

# Check dependencies
systemctl list-dependencies service_name

# Restart service with verbose output
sudo systemctl restart service_name
sudo journalctl -fu service_name

# Reset failed state
sudo systemctl reset-failed service_name

# Check if port is already in use
sudo lsof -i :80             # Check port 80
sudo netstat -tulpn | grep :80

# Check file permissions
ls -la /etc/service_name/
ls -la /var/log/service_name/

# Reload service daemon
sudo systemctl daemon-reload
```

---

## Network Emergency Commands

### No Internet Connection

```bash
# Step 1: Check physical connection
ip link show                 # Interface up?
ethtool eth0                 # Cable connected?

# Step 2: Check IP address
ip addr show
# Should see IP like 192.168.x.x or 10.x.x.x

# Step 3: Check default gateway
ip route show
ping $(ip route | grep default | awk '{print $3}')

# Step 4: Check DNS
cat /etc/resolv.conf
ping 8.8.8.8                 # Google DNS (bypass local DNS)
ping google.com              # Test DNS resolution

# Step 5: Restart network
sudo systemctl restart NetworkManager
sudo dhclient -r             # Release DHCP
sudo dhclient                # Request new DHCP

# Step 6: Check firewall
sudo iptables -L
sudo ufw status              # Ubuntu firewall
```

### Diagnose Slow Network

```bash
# Check bandwidth
speedtest-cli                # Install: apt install speedtest-cli

# Check latency and packet loss
ping -c 100 google.com
mtr google.com               # Better than traceroute

# Check network interface errors
ip -s link                   # Interface statistics
ifconfig                     # TX/RX errors

# Monitor bandwidth usage
iftop                        # By connection
nethogs                      # By process
vnstat                       # Historical stats

# Check for DNS issues
nslookup google.com
dig google.com
time dig google.com          # DNS response time
```

### Firewall Blocking Everything

```bash
# Check firewall status
sudo iptables -L -v -n       # List rules
sudo ufw status              # Ubuntu
sudo firewall-cmd --list-all # CentOS/RHEL

# Emergency: Flush all rules (allows everything)
sudo iptables -F
sudo iptables -X
sudo iptables -P INPUT ACCEPT
sudo iptables -P FORWARD ACCEPT
sudo iptables -P OUTPUT ACCEPT

# UFW emergency disable
sudo ufw disable

# firewalld emergency disable
sudo systemctl stop firewalld
```

---

## Security & Access Recovery

### SSH Access Issues

```bash
# Check SSH service
sudo systemctl status sshd
sudo systemctl restart sshd

# Check SSH configuration
sudo sshd -t                 # Test config
sudo cat /etc/ssh/sshd_config

# Common fixes in /etc/ssh/sshd_config:
# PermitRootLogin yes
# PasswordAuthentication yes
# PubkeyAuthentication yes

# Check SSH logs
sudo tail -f /var/log/auth.log
sudo journalctl -u sshd -f

# Test SSH locally
ssh localhost

# Check SSH port
sudo netstat -tulpn | grep :22
sudo lsof -i :22

# Regenerate SSH host keys (if corrupted)
sudo rm /etc/ssh/ssh_host_*
sudo dpkg-reconfigure openssh-server
```

### File Permission Recovery

```bash
# Reset permissions to defaults

# For /home directory
sudo chmod 755 /home/username
sudo chmod 700 /home/username/.ssh
sudo chmod 600 /home/username/.ssh/authorized_keys
sudo chown -R username:username /home/username

# For web directories
sudo chown -R www-data:www-data /var/www
sudo find /var/www -type d -exec chmod 755 {} \;
sudo find /var/www -type f -exec chmod 644 {} \;

# For system binaries
sudo chmod 755 /usr/bin/*
sudo chmod 755 /usr/sbin/*

# Reset entire filesystem permissions (DANGEROUS!)
# Only as last resort from live USB
sudo chmod -R a+rX /mnt/system
```

### SELinux/AppArmor Issues

```bash
# SELinux (CentOS/RHEL)
getenforce                   # Check status
sudo setenforce 0            # Temporarily disable
# Edit /etc/selinux/config and set SELINUX=permissive

# Check SELinux denials
sudo ausearch -m avc -ts recent
sudo audit2why -a           # Explain denials

# AppArmor (Ubuntu/Debian)
sudo aa-status               # Check status
sudo aa-complain /path/to/profile  # Set to complain mode
sudo aa-disable /path/to/profile   # Disable profile
```

---

## Quick Reference Card

### One-Liners for Emergencies

```bash
# Kill all processes for user
sudo pkill -u username

# Find biggest files
sudo find / -type f -size +100M -exec ls -lh {} \; 2>/dev/null

# Check if system is 32 or 64 bit
uname -m

# Emergency sync and reboot
sync && sudo reboot -f

# Empty trash
rm -rf ~/.local/share/Trash/*

# Clear bash history
history -c && history -w

# Find recently modified files
find /etc -mtime -1 -ls

# Check which process is using a file
lsof /path/to/file

# Check what files a process is using
lsof -p PID

# Emergency shutdown
sudo shutdown -h now
sudo poweroff
sudo init 0

# Copy with progress bar
rsync -ah --progress source destination

# Monitor command every 2 seconds
watch -n 2 'df -h'

# Generate random password
openssl rand -base64 32

# Check last reboot
last reboot

# Show all listening ports and programs
sudo netstat -tulpn | grep LISTEN
```

---

## Essential Emergency Kit Commands

These should be available even in minimal rescue environments:

```bash
# Navigation
cd, pwd, ls

# File operations
cp, mv, rm, cat, less, vi

# System
mount, umount, df, ps, kill, reboot

# Network
ip, ping, netstat

# Disk
fdisk, mkfs, fsck, dd

# Permissions
chmod, chown, ls -l

# Process
ps, kill, killall, top

# Archive
tar, gzip, gunzip

# Text
grep, sed, awk, cut, sort

# System info
uname, hostname, uptime, free
```
