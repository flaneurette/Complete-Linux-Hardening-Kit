# Auto-enable-UFW
Installs and enables UFW if uninstalled or disabled.

# Issue it fixes

Some Linux packages can **silently** uninstall UFW because they conflict with it or are not compatible. For example, the package `netfilter-persistent` can remove UFW during installation, leaving your system without an active firewall!

To prevent this, check_ufw.sh is a Bash script that:

Checks every 5 minutes if the UFW firewall is running.

- If UFW is missing, installs it.

- If UFW is installed but inactive, enables it.

- Only sends an email notification to the site owner if something fails or UFW had to be installed/enabled.

You can customize the email address directly in the script.

# Install

`sudo apt install mailutils`

`sudo touch /usr/local/bin/check_ufw.sh`

`sudo nano /usr/local/bin/check_ufw.sh`

paste the check_ufw.sh script

`Ctrl+O`

`Ctrl+X`

`sudo chmod +x /usr/local/bin/check_ufw.sh`

`sudo crontab -e`

Paste at the end:

`*/5 * * * * /usr/local/bin/check_ufw.sh`

# Why
Here are the reasons: see UFW bug report that I filed: https://bugs.launchpad.net/ubuntu/+source/ufw/+bug/2133823

---

## Extra: Post DPkg hook.

To automatically check after each DPkg call, we can run it automatically with a hook invoking it immediately (while keeping the cron). This runs instantly in mere seconds. If your infra structure is critical I recommened adding this hook:

Install hook:

`sudo touch /etc/apt/apt.conf.d/99-ufw-check`

`sudo nano /etc/apt/apt.conf.d/99-ufw-check`

Add this line to it:

`DPkg::Post-Invoke { "if [ -x /usr/local/bin/check_ufw.sh ]; then /usr/local/bin/check_ufw.sh; fi"; };`

Save it:

`Ctrl+O`

`Ctrl+X`

## Extra: Add APT update hook:

This runs after every `apt update` command instantly in mere seconds. If your infra structure is critical I recommened adding this hook as well:

`sudo touch /etc/apt/apt.conf.d/99-ufw-update-hook`

`sudo nano /etc/apt/apt.conf.d/99-ufw-update-hook`

Add this line to it:

`APT::Update::Post-Invoke { "if [ -x /usr/local/bin/check_ufw.sh ]; then /usr/local/bin/check_ufw.sh; fi"; };`

Save it:

`Ctrl+O`

`Ctrl+X`

## Done.
Enjoy.


