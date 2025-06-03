#!/bin/bash

# Get a list of running container names
containers=($(docker ps --format "{{.Names}}" | cut -d' ' -f1))

# Verify that there is at least one container running
if [ ${#containers[@]} -eq 0 ]; then
    echo "There are no running containers."
    exit 1
fi

# Use fzf to select a container
selected_container=$(printf '%s\n' "${containers[@]}" | fzf --prompt="Select a container: ")

# Check if a container was selected
if [ -z "$selected_container" ]; then
    echo "No container selected. Please try again."
    exit 1
fi

docker logs "$selected_container"
