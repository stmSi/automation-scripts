#!/bin/bash

# Check if the input URL is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <GitHub file URL>"
  exit 1
fi

# Convert the GitHub URL to the raw URL
url="$1"
raw_url=$(echo "$url" | sed 's/github\.com/raw.githubusercontent.com/' | sed 's/blob\///')

# Download the file using curl
filename=$(basename "$raw_url")
curl -L -o "$filename" "$raw_url"

echo "Downloaded file: $filename"

