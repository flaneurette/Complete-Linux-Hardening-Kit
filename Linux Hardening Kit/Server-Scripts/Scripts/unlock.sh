#!/bin/bash

# Remove common lock files
sudo rm -f /var/lib/dpkg/lock-frontend
sudo rm -f /var/lib/dpkg/lock
sudo rm -f /var/cache/apt/archives/lock
sudo rm -f /var/lib/apt/lists/lock

echo "Lock files removed. Repairing package database..."

# Repair broken installs
sudo dpkg --configure -a
sudo apt-get install -f
sudo apt-get update

echo "All done! apt/dpkg should now be unlocked."
