#!/bin/bash

docker ps --format "{{.ID}} {{.Image}}" | while read -r container_id image_name; do
    mem_usage=$(docker stats --no-stream --format "{{ .MemUsage }}" "$container_id" | awk '{
        split($1, arr, "/")
        value = arr[1]
        gsub(/[^0-9.]/, "", value)
        unit = "MiB"
        if (index($1, "GiB") != 0) {
            value *= 1024
        } else if (index($1, "KiB") != 0) {
            value /= 1024
        }
        print value
    }')
    echo "$container_id ($image_name): $mem_usage MiB"
done

total=$(docker stats --no-stream --format "{{ .MemUsage }}" | awk '{
    split($1, arr, "/")
    value = arr[1]
    gsub(/[^0-9.]/, "", value)
    if (index($1, "GiB") != 0) {
        value *= 1024
    } else if (index($1, "KiB") != 0) {
        value /= 1024
    }
    total += value
} END {
    giB = total / 1024
    printf "%d MiB (%.1f GiB)\n", total, giB
}')

echo "Total: $total"
