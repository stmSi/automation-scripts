#!/bin/bash

# Get container IDs
container_ids=$(docker ps -q)

# Loop through each container ID
for id in $container_ids; do
    # Get container name and IP address
    container_name=$(docker inspect --format '{{.Name}}' $id | sed 's/^\/\([^ ]*\).*/\1/')
    container_ip=$(docker inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $id)

    # Print container ID, Name, and IP address
    echo "ID: $id, Name: $container_name, IP: $container_ip"
done
