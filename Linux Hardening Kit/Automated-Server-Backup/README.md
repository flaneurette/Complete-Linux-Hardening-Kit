# Automated Server Backup

Automatically create **server backups on Linux**, encrypted with your **GPG key**, and automatically download the encrypted backups on Windows on a weekly basis. 

The script has several checks:

- checks available diskspace first
- excludes backups, gpg files inside every new backup.
- send an email on failures.
- removes plain backups after encryption
  
---

> For even more security (quantum decryption prevention), consider generating a secure 256 bits keyfile to encrypt backups:
> 
> https://github.com/flaneurette/Hardening-Encryption-on-Linux
> 
> But in most user cases, this is not required. Only do this if you have many secrets you need to protect or are like a state actor/agency.

## All Requirements

- `putty.exe` (optional)
- `puttygen.exe` (optional)
- `pscp.exe` (required)
- A strong **GPG key** to encrypt the archive:
- GPG for Windows ([https://www.gpg4win.org/](https://gpg4win.org)) 
- Kleopatra (included in gpg4win)
- Linux commands: `tar, gpg, mail, df, du`

If possible, always download the required executables from the official channel. I added the executables inside the backup folder as a private backup, including the signatures.
All official executables can be found here:

https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html

> For brevity, we assume to run this from your Desktop to try it out. For better security, run everything from a secure USB stick, which you can attach and detach on a daily basis.

# On windows

Using Kleopatra to create a keypair for encryption (GUI)

*Remember: this is not your private key for SSH access!*

```
Open Kleopatra (installed with Gpg4win).
Go to File → New Certificate.
Select Create a personal OpenPGP key pair and click Next.
Enter your name and email (this identifies the key).
Optional: add a comment (e.g., “Server Backup Key”).
Choose key settings:
Key type: RSA and RSA (default)
Key size: 4096 bits (recommended)
Expiration: your choice (e.g., never expire or 1 year)
Click Create Key.
Enter a strong passphrase.
After creation, Kleopatra shows your public and private key.
```

**Export the keys**

Export public key: .asc or .pub file. This is the key you put on the server to allow encryption.

Keep private key secure. This stays on your **Windows PC** or USB stick, for decrypting backups. However, exporting the private key is usually not needed and can increase risks. If possible, store it on a USB drive and keep it offline for emergency only. If possible store it in a secure vault.

Then edit: ``Backup/Server-Backup.bat`` and set all required information.

## Linux Server installation

1. Install gpg.
```
sudo apt update
sudo apt install -y gnupg tar mailutils
# On your Linux server, import the public key so the backup script can encrypt files to it:
gpg --import /path/to/publickey.asc
# or:
gpg --import /path/to/publickey.pub
# Verify the key:
gpg --list-keys
```

2. Edit: backup.sh

These MUST be set. If you leave them empty, strange things can happen, and server files maybe **permanently deleted**.

```
Edit your key information: Name and E-mail address (required) and other configurations.
# -------- CONFIG --------
BACKUP_FILE="/secret/path/backup.tar.gz"
ENCRYPTED_FILE="/secret/path/backup.tar.gz.gpg"
LOG_FILE="/secret/path/backup.log"
RECIPIENT="Your Name <email@example.com>"   # GPG recipient, must match GPG key!
ALERT_EMAIL="backups@example.com"          # Where alerts will be sent
```

3. Navigate to `/usr/local/bin`:

```bash
cd /usr/local/bin
sudo nano backup.sh
```
Paste editted backup.sh script.
```
sudo chmod +x /usr/local/bin/backup.sh
```
## Cron
```bash
sudo crontab -e
```

Add the following line to run backups every Sunday at 2:00 AM and log the output:
```bash
0 2 * * 0 /usr/local/bin/backup.sh >> /secret/path/backup.log 2>&1
```

Save.

## On Windows, final step

1. Create a PuTTY private key using puttygen if you don’t have one yet.
2. Create a folder on your Desktop called `Backup` (or somewhere else,  edit all files to set it correct).
3. Then move these files into the folder:
   
```  
- pscp.exe
- Run-Backup.vbs
- Server-Backup.bat
- Your Putty private server key, i.e. privatekey.ppk (not your private GPG key!) this is required for pscp.exe to login to your server securely through ssh.
```

Then edit: ``Backup/Server-Backup.bat`` and set all required information.

## Run it manually, or schedule.

Manually:
To run it, click `Run-Backup.vbs`

Scheduled (Recommended)
Use Windows Task Scheduler:

Action → Start a program:
```
C:\Users\<USERNAME>\Desktop\Backup\Run-Backup.vbs
```

Schedule it weekly or daily as desired.

## Decryption

To decrypt the downloaded backup on Windows, open a CMD window and type:
```
gpg --decrypt backup.tar.gz.gpg > backup.tar.gz
```
  
