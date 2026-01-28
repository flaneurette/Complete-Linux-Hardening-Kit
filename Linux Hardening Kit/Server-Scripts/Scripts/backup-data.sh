#!/bin/bash
# Secure backup of web files and MySQL database with GPG encryption
# Requires .my.cnf in the backup user/root home for MySQL credentials
# And a GPG passphrase stored in a protected file
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Create /root/.my.cnf, add:
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# [client]
# user=user
# password=pass
# host=localhost
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# chmod 600 /root/.my.cnf
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# --- Config ---
DOMAIN="example.com"
BACKUP_DIR="/root/backup"
DB_NAME="user"
DATE=$(date +"%Y-%m-%d")

# File containing GPG passphrase (must be chmod 600)
GPG_PASSPHRASE_FILE="/root/backup_passphrase.txt"

mkdir -p "$BACKUP_DIR"

# --- Backup web files ---
WEB_TAR="$BACKUP_DIR/${DOMAIN}_files_${DATE}.tar.gz"
WEB_TAR_GPG="$WEB_TAR.gpg"

tar -czf "$WEB_TAR" "/var/www/$DOMAIN"
gpg --batch --yes --passphrase-file "$GPG_PASSPHRASE_FILE" -c "$WEB_TAR"
rm "$WEB_TAR"
echo "Web files backed up and encrypted: $WEB_TAR_GPG"

# --- Backup MySQL database ---
DB_SQL="$BACKUP_DIR/${DOMAIN}_db_${DATE}.sql"
DB_SQL_GPG="$DB_SQL.gpg"

# mysqldump reads credentials from ~/.my.cnf
mysqldump "$DB_NAME" > "$DB_SQL"
gpg --batch --yes --passphrase-file "$GPG_PASSPHRASE_FILE" -c "$DB_SQL"
rm "$DB_SQL"
echo "Database backed up and encrypted: $DB_SQL_GPG"

# --- Cleanup old backups ---
find "$BACKUP_DIR" -type f -name "*.gpg" -mtime +7 -delete
echo "Old backups (>7 days) deleted"
