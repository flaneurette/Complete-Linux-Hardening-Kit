#!/bin/bash
# -------- CONFIG --------
BACKUP_FILE="/root/server.tar.gz"
ENCRYPTED_FILE="/root/server.tar.gz.gpg"
LOG_FILE="/root/server-backup.log"
RECIPIENT="Name <hello@example.com>"
ALERT_EMAIL="alert@example.com"

# -------- FUNCTION TO SEND ALERT --------
send_alert() {
    SUBJECT="$1"
    BODY="$2"
    echo -e "$BODY" | mail -s "$SUBJECT" "$ALERT_EMAIL"
    echo "ALERT SENT: $SUBJECT" >> "$LOG_FILE"
}

# -------- FRESH LOG FILE --------
if [ -f "$LOG_FILE" ]; then
    rm -f "$LOG_FILE"
    touch "$LOG_FILE"
fi

# -------- START LOG --------
echo "========================================" >> "$LOG_FILE"
echo "Backup started at $(date)" >> "$LOG_FILE"
echo "========================================" >> "$LOG_FILE"

# -------- EXCLUDES --------
EXCLUDES=(
  /proc
  /sys
  /dev
  /run
  /tmp
  /mnt
  /media
  /lost+found
  /bin
  /sbin
  /lib
  /lib64
  /usr/bin
  /usr/sbin
  "$BACKUP_FILE"
  "$ENCRYPTED_FILE"
  "$LOG_FILE"
)

TAR_EXCLUDES=()
for i in "${EXCLUDES[@]}"; do
    TAR_EXCLUDES+=(--exclude="$i")
done

# -------- PRE-FLIGHT CHECKS --------
echo "Running pre-flight checks..." >> "$LOG_FILE"

# Check if required commands exist
for cmd in tar gpg mail df du; do
    if ! command -v "$cmd" &> /dev/null; then
        ERROR_MSG="Required command '$cmd' not found. Cannot proceed."
        echo "$ERROR_MSG" >> "$LOG_FILE"
        send_alert "Backup Failed - Missing Command" "$ERROR_MSG"
        exit 1
    fi
done

# Check GPG key
if ! gpg --list-keys "$RECIPIENT" &> /dev/null; then
    ERROR_MSG="GPG key for '$RECIPIENT' not found. Cannot encrypt backup."
    echo "$ERROR_MSG" >> "$LOG_FILE"
    send_alert "Backup Failed - GPG Key Missing" "$ERROR_MSG"
    exit 1
fi

# -------- CALCULATE REQUIRED SPACE --------
echo "Calculating required disk space..." >> "$LOG_FILE"

# Get uncompressed size of directories
REQUIRED_SPACE=$(du -xsc /etc /home /var/www /root /var/lib/mysql 2>/dev/null | grep total$ | awk '{print $1}')
echo "Uncompressed size: $REQUIRED_SPACE KB" >> "$LOG_FILE"

# Estimate compressed size (assume 30% compression ratio for safety)
COMPRESSED_ESTIMATE=$((REQUIRED_SPACE * 70 / 100))
echo "Estimated compressed size: $COMPRESSED_ESTIMATE KB" >> "$LOG_FILE"

# Account for temporary encrypted file (add another copy)
TOTAL_REQUIRED=$((COMPRESSED_ESTIMATE * 2))
echo "Total space required (compressed + encrypted): $TOTAL_REQUIRED KB" >> "$LOG_FILE"

# Add 20% safety buffer
TOTAL_REQUIRED=$((TOTAL_REQUIRED + TOTAL_REQUIRED/5))
echo "With 20% buffer: $TOTAL_REQUIRED KB" >> "$LOG_FILE"

# Available space
AVAILABLE_SPACE=$(df --output=avail /root | tail -1)
echo "Available space: $AVAILABLE_SPACE KB" >> "$LOG_FILE"

if [ "$AVAILABLE_SPACE" -lt "$TOTAL_REQUIRED" ]; then
    ERROR_MSG="Insufficient disk space.
Required: $TOTAL_REQUIRED KB ($(($TOTAL_REQUIRED/1024)) MB)
Available: $AVAILABLE_SPACE KB ($(($AVAILABLE_SPACE/1024)) MB)
Shortfall: $(($TOTAL_REQUIRED - $AVAILABLE_SPACE)) KB ($((($TOTAL_REQUIRED - $AVAILABLE_SPACE)/1024)) MB)"
    echo "$ERROR_MSG" >> "$LOG_FILE"
    send_alert "Backup Failed - Insufficient Disk Space" "$ERROR_MSG"
    exit 1
fi

echo "Disk space check passed." >> "$LOG_FILE"

# -------- CREATE BACKUP --------
echo "Creating backup archive..." >> "$LOG_FILE"
ERROR_LOG=$(mktemp)

# Run tar and capture exit code
set +e
sudo tar -czf "$BACKUP_FILE" --ignore-failed-read "${TAR_EXCLUDES[@]}" / 2>"$ERROR_LOG"
TAR_EXIT=$?
set -e

# Check tar exit code
if [ $TAR_EXIT -eq 0 ]; then
    echo "Backup created successfully." >> "$LOG_FILE"
elif [ $TAR_EXIT -eq 1 ]; then
    # Exit 1 means "some files changed while being read" - acceptable
    echo "Backup created with warnings (files changed during backup)." >> "$LOG_FILE"
else
    # Exit 2+ means fatal error
    ERROR_MSG="Backup creation FAILED at $(date). tar exit code: $TAR_EXIT

Error details:
$(cat "$ERROR_LOG")

This usually indicates:
- Out of disk space during compression
- Permission denied on critical files
- I/O errors on disk"
    echo -e "$ERROR_MSG" >> "$LOG_FILE"
    send_alert "Backup FAILED - tar Error" "$ERROR_MSG"
    rm -f "$BACKUP_FILE"
    exit 1
fi

# Check if backup file was created and has reasonable size
if [ ! -f "$BACKUP_FILE" ]; then
    ERROR_MSG="Backup file was not created at $BACKUP_FILE"
    echo "$ERROR_MSG" >> "$LOG_FILE"
    send_alert "Backup FAILED - File Not Created" "$ERROR_MSG"
    exit 1
fi

BACKUP_SIZE=$(stat -c%s "$BACKUP_FILE" 2>/dev/null || echo 0)
BACKUP_SIZE_MB=$((BACKUP_SIZE / 1024 / 1024))
echo "Backup file size: $BACKUP_SIZE_MB MB" >> "$LOG_FILE"

if [ "$BACKUP_SIZE" -lt 1048576 ]; then  # Less than 1MB is suspicious
    ERROR_MSG="Backup file is suspiciously small ($BACKUP_SIZE_MB MB). Something may have gone wrong."
    echo "$ERROR_MSG" >> "$LOG_FILE"
    send_alert "Backup Warning - Small File Size" "$ERROR_MSG"
fi

# Log any non-critical errors from tar
if [ -s "$ERROR_LOG" ]; then
    echo "Non-critical warnings from tar:" >> "$LOG_FILE"
    cat "$ERROR_LOG" >> "$LOG_FILE"
fi

rm -f "$ERROR_LOG"

# -------- ENCRYPT BACKUP --------
echo "Encrypting backup..." >> "$LOG_FILE"

set +e
gpg --batch --yes --trust-model always --encrypt --recipient "$RECIPIENT" -o "$ENCRYPTED_FILE" "$BACKUP_FILE" 2>"$ERROR_LOG"
GPG_EXIT=$?
set -e

if [ $GPG_EXIT -eq 0 ] && [ -f "$ENCRYPTED_FILE" ]; then
    ENCRYPTED_SIZE=$(stat -c%s "$ENCRYPTED_FILE" 2>/dev/null || echo 0)
    ENCRYPTED_SIZE_MB=$((ENCRYPTED_SIZE / 1024 / 1024))
    echo "Backup encrypted successfully. Size: $ENCRYPTED_SIZE_MB MB" >> "$LOG_FILE"
    echo "Removing unencrypted backup..." >> "$LOG_FILE"
    rm -f "$BACKUP_FILE"
else
    ERROR_MSG="Backup encryption FAILED at $(date). GPG exit code: $GPG_EXIT

Error details:
$(cat "$ERROR_LOG")

Unencrypted backup remains at: $BACKUP_FILE"
    echo -e "$ERROR_MSG" >> "$LOG_FILE"
    send_alert "Backup FAILED - Encryption Error" "$ERROR_MSG"
    exit 1
fi

# -------- FINAL SUMMARY --------
echo "========================================" >> "$LOG_FILE"
echo "Backup completed successfully at $(date)" >> "$LOG_FILE"
echo "Encrypted file: $ENCRYPTED_FILE ($ENCRYPTED_SIZE_MB MB)" >> "$LOG_FILE"
echo "========================================" >> "$LOG_FILE"

# Optional: Send success notification (comment out if you only want failure alerts)
# send_alert "Backup Completed Successfully" "Backup completed at $(date)\nFile size: $ENCRYPTED_SIZE_MB MB"

exit 0
