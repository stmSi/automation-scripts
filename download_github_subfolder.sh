#!/bin/bash

# Check if input URL and API token are provided
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: $0 <GitHub repo subfolder URL> <GitHub API token>"
  exit 1
fi

# Extract user, repo, and branch information from the input URL
url="$1"
api_token="$2"
repo_user=$(echo "$url" | awk -F '/' '{print $4}')
repo_name=$(echo "$url" | awk -F '/' '{print $5}')
branch=$(echo "$url" | awk -F '/' '{print $7}')
subfolder_path=$(echo "$url" | awk -F '/' '{print substr($0, index($0,$8))}')

# Fetch repo contents using GitHub API
api_url="https://api.github.com/repos/$repo_user/$repo_name/contents/$subfolder_path?ref=$branch"
content_list=$(curl -H "Authorization: token $api_token" -s "$api_url" | jq -r '.[] | .download_url')

# Download each file using download_github_file.sh script
IFS=$'\n'
for file_url in $content_list; do
  if [ "$file_url" != "null" ]; then
    ./download_github_file.sh "$file_url"
  fi
done

