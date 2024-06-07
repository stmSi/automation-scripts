#!/bin/bash

# Prompt the user for file names
read -p "Enter the name for the private key file (default: private.key): " PRIVATE_KEY
PRIVATE_KEY=${PRIVATE_KEY:-private.key}

read -p "Enter the name for the CSR file (default: request.csr): " CSR_FILE
CSR_FILE=${CSR_FILE:-request.csr}

# Check if the private key already exists
if [ -f "$PRIVATE_KEY" ]; then
    read -p "Private key '$PRIVATE_KEY' already exists. Do you want to overwrite it? (y/n): " choice
    case "$choice" in
        y|Y ) echo "Overwriting private key...";;
        n|N ) echo "Exiting script."; exit 1;;
        * ) echo "Invalid choice. Exiting script."; exit 1;;
    esac
fi

# Generate the private key without a passphrase
openssl genpkey -algorithm RSA -out $PRIVATE_KEY

# Check if the CSR file already exists
if [ -f "$CSR_FILE" ]; then
    read -p "CSR file '$CSR_FILE' already exists. Do you want to overwrite it? (y/n): " choice
    case "$choice" in
        y|Y ) echo "Overwriting CSR file...";;
        n|N ) echo "Exiting script."; exit 1;;
        * ) echo "Invalid choice. Exiting script."; exit 1;;
    esac
fi

# Generate the CSR
openssl req -new -key $PRIVATE_KEY -out $CSR_FILE

# Convert the CSR to a single line string and copy to clipboard
awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' $CSR_FILE | xclip -selection clipboard

echo "CSR has been generated and copied to the clipboard."
