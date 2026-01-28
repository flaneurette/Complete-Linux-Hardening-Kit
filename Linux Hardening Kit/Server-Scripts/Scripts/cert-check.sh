#!/bin/bash
read -p "Enter domain name: " DOMAIN

echo "Checking SSL certificate for $DOMAIN..."

EXPIRY=$(echo | openssl s_client -servername "$DOMAIN" -connect "$DOMAIN":443 2>/dev/null | \
    openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)

if [ -n "$EXPIRY" ]; then
    EXPIRY_EPOCH=$(date -d "$EXPIRY" +%s)
    NOW_EPOCH=$(date +%s)
    DAYS_LEFT=$(( ($EXPIRY_EPOCH - $NOW_EPOCH) / 86400 ))
    
    echo "Certificate expires: $EXPIRY"
    echo "Days remaining: $DAYS_LEFT"
    
    if [ $DAYS_LEFT -lt 30 ]; then
        echo "WARNING: Certificate expires soon!"
    fi
else
    echo "Could not retrieve certificate"
fi
