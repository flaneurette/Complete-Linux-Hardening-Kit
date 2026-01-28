#!/bin/bash
read -p "Enter port number: " PORT

echo "=== Process using port $PORT ==="

# Using lsof
if command -v lsof &> /dev/null; then
    lsof -i :$PORT
fi

# Using netstat
if command -v netstat &> /dev/null; then
    netstat -tulpn | grep ":$PORT"
fi

# Using ss (modern alternative)
if command -v ss &> /dev/null; then
    ss -tulpn | grep ":$PORT"
fi
