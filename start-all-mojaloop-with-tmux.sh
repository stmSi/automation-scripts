#!/usr/bin/env bash

# Function to start a service if it's not running
ensure_service() {
  local name="$1"
  local svc="$2"
  if ! systemctl is-active --quiet "$svc"; then
    echo "Starting $name..."                                                                                                                                             [    sudo systemctl start "$svc"
  else
    echo "$name is already running."
  fi
}

# Ensure required services are running or start them
ensure_service "MySQL" mysql
ensure_service "MongoDB" mongod
ensure_service "Kafka" kafka
ensure_service "Redis" redis-server

# Start Redis Cluster
sudo redis-server /etc/redis/redis-6379.conf
sudo redis-server /etc/redis/redis-6380.conf
sudo redis-server /etc/redis/redis-6381.conf

# Name of the tmux session
SESSION="services"

# If the session already exists, attach; otherwise create a new detached session
tmux has-session -t $SESSION 2>/dev/null
if [ $? != 0 ]; then
  tmux new-session -d -s $SESSION
fi

first=true

# Loop over every subdirectory in the current directory
for dir in */; do
  # Strip the trailing slash to get the window name
  win_name="${dir%/}"

  if $first; then
    # Rename the default window (0) to the first service name
    tmux rename-window -t ${SESSION}:0 "$win_name"
    # In that window, cd into the folder and run npm start
    tmux send-keys -t ${SESSION}:0 "cd $dir && npm run start" C-m
    first=false
  else
    # Create a new window for each subsequent service
    tmux new-window -t $SESSION -n "$win_name"
    tmux send-keys -t ${SESSION}:"$win_name" "cd $dir && npm run start" C-m
  fi
done

# Finally, attach to the session
tmux attach-session -t $SESSION
