#!/bin/bash

EMAIL="youremail@example.com"

HOSTNAME=$(hostname)

# Function to send email
send_email() {
    local SUBJECT="$1"
    local BODY="$2"
    echo "$BODY" | mail -s "$SUBJECT" "$EMAIL"
}

# Check if ufw is installed
if ! command -v ufw &> /dev/null; then
    sudo apt update && sudo apt install -y ufw
    if [ $? -eq 0 ]; then
        send_email "UFW Installed on $HOSTNAME" "UFW was missing on $HOSTNAME and has been installed."
    else
        send_email "UFW Installation Failed on $HOSTNAME" "Attempted to install UFW on $HOSTNAME, but the installation failed!"
    fi
else
    # Check if UFW is active
    if ! sudo ufw status | grep -q "Status: active"; then
        sudo ufw --force enable
        if [ $? -eq 0 ]; then
            send_email "UFW Enabled on $HOSTNAME" "UFW was inactive on $HOSTNAME and has now been enabled."
        else
            send_email "UFW Failed to Enable on $HOSTNAME" "UFW is installed but failed to enable on $HOSTNAME."
        fi
    fi
fi
