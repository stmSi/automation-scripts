#!/bin/bash

# Set the path to the registered_paths file
REGISTERED_PATHS_FILE=~/.registered_paths

# Register the current folder path
echo "$(pwd)" >> $REGISTERED_PATHS_FILE

# Remove duplicate paths
awk '!seen[$0]++' $REGISTERED_PATHS_FILE > "${REGISTERED_PATHS_FILE}.tmp" && mv "${REGISTERED_PATHS_FILE}.tmp" $REGISTERED_PATHS_FILE

