#!/bin/bash
# add your service... apache2, nginx, etc.
SERVICE="nginx"

if ! systemctl is-active --quiet $SERVICE; then
  echo "$SERVICE is down, attempting restart..."
  systemctl restart $SERVICE
  sleep 5
  if systemctl is-active --quiet $SERVICE; then
    echo "$SERVICE restarted successfully"
  else
    echo "CRITICAL: Failed to restart $SERVICE"
  fi
fi
