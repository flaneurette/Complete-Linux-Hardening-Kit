#!/bin/bash

echo "Secure Password Generator"

# Ask for length
read -p "Enter password length: " length

# Ask for character set
echo "Choose character set:"
echo "1) Letters only"
echo "2) Letters + Numbers"
echo "3) Letters + Numbers + Symbols"
read -p "Enter choice (1-3): " choice

# Ask for optional hashing
echo "Optional: hash password?"
echo "1) None"
echo "2) SHA256"
echo "3) SHA512"
read -p "Enter choice (1-3): " hash_choice

# Define charset
case $choice in
  1) charset='A-Za-z' ;;
  2) charset='A-Za-z0-9' ;;
  3) charset='A-Za-z0-9!@#$%^&*()_+~;:?<>=-' ;;
  *) echo "Invalid choice, defaulting to Letters + Numbers"; charset='A-Za-z0-9' ;;
esac

# Function to generate password securely
generate_password() {
    tr -dc "$charset" < /dev/urandom | head -c "$length"
}

# Output password directly or hashed
case $hash_choice in
  1)
    echo "Generated Password:"
    generate_password
    ;;
  2)
    echo "Generated SHA256 Hash:"
    generate_password | sha256sum | awk '{print $1}'
    ;;
  3)
    echo "Generated SHA512 Hash:"
    generate_password | sha512sum | awk '{print $1}'
    ;;
  *)
    echo "Generated Password:"
    generate_password
    ;;
esac
echo
