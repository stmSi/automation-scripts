#!/bin/bash

# Set the path to the registered_paths file
REGISTERED_PATHS_FILE=~/.registered_paths

# Check if registered paths file exists
if [ ! -f "$REGISTERED_PATHS_FILE" ]; then
    echo "No registered paths."
    exit 1
fi

# Use fzf to allow the user to select a path to unregister
UNREGISTER_PATH=$(cat $REGISTERED_PATHS_FILE | fzf)

# If a path is selected (fzf returns 0), unregister it
if [ $? -eq 0 ]; then
    echo "Unregistering path: $UNREGISTER_PATH"
    
    # Filter the selected path out of the registered paths
    awk -v path="$UNREGISTER_PATH" '$0 != path' $REGISTERED_PATHS_FILE > "${REGISTERED_PATHS_FILE}.tmp" && mv "${REGISTERED_PATHS_FILE}.tmp" $REGISTERED_PATHS_FILE

    echo "Path unregistered."
else
    echo "No path selected."
fi
