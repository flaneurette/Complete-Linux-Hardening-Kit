#!/bin/bash
read -p "Enter username: " USERNAME

echo "=== Login history for $USERNAME ==="
last $USERNAME | head -20

echo -e "\n=== Failed login attempts ==="
grep "Failed password" /var/log/auth.log | grep "$USERNAME" | tail -10
