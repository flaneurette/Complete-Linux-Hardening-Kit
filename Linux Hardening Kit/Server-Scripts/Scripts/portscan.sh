#!/bin/bash

# Prompt for host/IP
read -p "Enter hostname or IP address: " HOST

# Validate input
if [ -z "$HOST" ]; then
    echo "Error: Host cannot be empty"
    exit 1
fi

# Prompt for port range with defaults
read -p "Enter start port [default: 20]: " START_PORT
START_PORT=${START_PORT:-20}

read -p "Enter end port [default: 100]: " END_PORT
END_PORT=${END_PORT:-100}

# Validate port numbers
if ! [[ "$START_PORT" =~ ^[0-9]+$ ]] || ! [[ "$END_PORT" =~ ^[0-9]+$ ]]; then
    echo "Error: Ports must be numbers"
    exit 1
fi

if [ "$START_PORT" -gt "$END_PORT" ]; then
    echo "Error: Start port must be less than or equal to end port"
    exit 1
fi

echo ""
echo "========================================="
echo "Scanning $HOST from port $START_PORT to $END_PORT..."
echo "Started at: $(date)"
echo "========================================="

# Counter for open ports
OPEN_COUNT=0

# Scan ports
for PORT in $(seq $START_PORT $END_PORT); do
    if timeout 1 bash -c "echo >/dev/tcp/$HOST/$PORT" 2>/dev/null; then
        echo "Port $PORT is OPEN"
        ((OPEN_COUNT++))
    fi
done

echo "========================================="
echo "Scan completed at: $(date)"
echo "Total open ports found: $OPEN_COUNT"
echo "========================================="
