#!/bin/bash

# Get a list of running container names
containers=($(docker ps --format "{{.Names}}" | cut -d' ' -f1))

# Verify that there is at least one container running
if [ ${#containers[@]} -eq 0 ]; then
    echo "There are no running containers."
    exit 1
fi

# Use fzf to select one or more containers (multi-selection enabled)
# Can multi-select with Tab and Shift+Tab
selected_containers=($(printf '%s\n' "${containers[@]}" | fzf --multi --prompt="Select containers: "))

# Check if any container was selected
if [ ${#selected_containers[@]} -eq 0 ]; then
    echo "No container selected. Please try again."
    exit 1
fi

# Loop through the selected containers and stop each one concurrently
for container in "${selected_containers[@]}"; do
    echo "Stopping container: $container"
    docker stop "$container" &
done

# Wait for all background processes to finish
wait

echo "All selected containers have been stopped."
