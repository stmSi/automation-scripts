#!/bin/bash

# Define the session name and the target directory
SESSION_NAME="vnext-cross-cutting"
TARGET_DIR="/home/stm/work/platform-shared-tools/packages/deployment/docker-compose-cross-cutting"

# Check if the target directory exists
if [ ! -d "$TARGET_DIR" ]; then
    echo "Target directory does not exist: $TARGET_DIR"
    exit 1
fi

# Check if tmux is installed
if ! command -v tmux &> /dev/null; then
    echo "tmux could not be found. Please install tmux."
    exit 1
fi

# Create a new tmux session
tmux new-session -d -s "$SESSION_NAME" -n "vnext-corss-cutting" -c "$TARGET_DIR"

# Send keys to navigate to the target directory and run the script
# tmux send-keys -t "$SESSION_NAME" "cd $TARGET_DIR" C-m
tmux send-keys -t "$SESSION_NAME" "./start.sh" C-m

# Attach to the newly created session
tmux attach-session -t "$SESSION_NAME"
