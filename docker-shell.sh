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

# Define an array of shell options
shells=("/bin/sh" "/bin/bash")

# Use fzf to select a shell
selected_shell=$(printf '%s\n' "${shells[@]}" | fzf --prompt="Select a shell: ")

# Check if a shell was selected
if [ -z "$selected_shell" ]; then
    echo "No shell selected. Please try again."
    exit 1
fi

read -p "Need Root Access?(y/N)" need_root_access
root_access=""
if [ "$need_root_access" == "y" ]; then
  root_access="-u root "
fi

echo "Executing: docker exec $root_access -it $selected_container $selected_shell"
# Execute the "docker exec" command with the chosen container and shell
docker exec $root_access -it "$selected_container" "$selected_shell"
