#!/bin/bash

# Get a list of running container names
containers=($(docker ps --format "{{.Names}}" | cut -d' ' -f1))

# Verify that there is at least one container running
if [ ${#containers[@]} -eq 0 ]; then
    echo "There are no running containers."
    exit 1
fi

# Initialize an empty array to store used colors
used_colors=()
last_color=0

# Display the list of container names with numbered options and randomized colors
echo "Choose a container to execute the command:"
for i in "${!containers[@]}"; do
    # Generate a random color between 31 and 37 that has not already been used
    while true; do
        color=$((31 + $RANDOM % 6)) # Generate a random color between 31 and 37
        if ! [[ "$color" =~ "$last_color" ]]; then
            last_color=$color
            break
        fi
    done
    echo -e "\033[${color}m[$((i+1))] ${containers[$i]}\033[0m"
done

# Prompt the user to choose a container number
read -p "Enter a number [1-${#containers[@]}]: " container_number

# Verify that the user entered a valid container number
if ! [[ "$container_number" =~ ^[0-9]+$ ]] || [ "$container_number" -gt "${#containers[@]}" ] || [ "$container_number" -lt 1 ]; then
    echo "Invalid container number. Please try again."
    exit 1
fi

# Define an array of shell options
shells=("/bin/sh" "/bin/bash")

# Display the list of shell options with numbered options
echo "Choose a shell to use:"
for i in "${!shells[@]}"; do
    echo "[$((i+1))] ${shells[$i]}"
done

# Prompt the user to choose a shell number
read -p "Enter a number [1-${#shells[@]}]: " shell_number

# Verify that the user entered a valid shell number
if ! [[ "$shell_number" =~ ^[0-9]+$ ]] || [ "$shell_number" -gt "${#shells[@]}" ] || [ "$shell_number" -lt 1 ]; then
    echo "Invalid shell number. Please try again."
    exit 1
fi

echo docker exec -it "${shells[$shell_number-1]}" "${containers[$container_number-1]}"
# Execute the "docker exec" command with the chosen container and shell
docker exec -it "${containers[$container_number-1]}" "${shells[$shell_number-1]}" 

