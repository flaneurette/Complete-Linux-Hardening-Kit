#!/bin/bash
read -p "Enter directory to scan: " DIR
read -p "Find files larger than (MB): " SIZE

echo "Files larger than ${SIZE}MB in $DIR:"
find "$DIR" -type f -size +${SIZE}M -exec ls -lh {} \; | awk '{print $9, $5}'

read -p "Delete these files? (yes/no): " CONFIRM
if [ "$CONFIRM" == "yes" ]; then
    find "$DIR" -type f -size +${SIZE}M -delete
    echo "Files deleted"
fi
