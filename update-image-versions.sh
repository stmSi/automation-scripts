#!/bin/bash

# Check if a file name is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <docker-compose-file>"
    exit 1
fi

# The file path of the docker-compose file
file_path="$1"

# Check if the file exists
if [ ! -f "$file_path" ]; then
    echo "Error: File does not exist."
    exit 1
fi

# Function to fetch the latest tag from Docker Hub
function get_latest_tag() {
    image_name=$1
    # Fetch tags using Docker Hub API and extract the latest by date (this requires `jq` installed)
    curl -s "https://registry.hub.docker.com/v2/repositories/${image_name}/tags?page_size=1024" | jq -r '.results | sort_by(.last_updated) | last(.[]).name'

    # Alternative: Fetch tags using Docker Hub API and extract the latest by version
}

# Read through docker-compose file and update image versions
while IFS= read -r line; do
    if [[ "$line" =~ ^[[:space:]]*image:[[:space:]]*([^:]+)(:.+)? ]]; then
        image_name="${BASH_REMATCH[1]}"
        latest_tag=$(get_latest_tag "$image_name")
        echo "Latest tag for '$image_name' is '$latest_tag'."
        if [ -n "$latest_tag" ]; then
            # Replace the line with the new tag
            printf '%s\n' "$line" | sed -i.bak -E "s|($image_name)(:.+)?|$image_name:$latest_tag|" "$file_path"
            # sed -i.bak -E "s|($image_name)(:.+)?|$image_name:$latest_tag|" "$file_path"
        fi
    fi
done < "$file_path"

echo "Image versions in '$file_path' have been updated to the latest available tags."
