#!/usr/bin/env bash

# ▶️ CONFIGURATION
DIR="$HOME/Pictures/Screenshots"
mkdir -p "$DIR"  # ensure the folder exists

TIMESTAMP="$(date +'%Y-%m-%d_%H-%M-%S')"
FILE="$DIR/screenshot_$TIMESTAMP.png"

# ▶️ MODE SELECTION
if [ "$1" = "area" ]; then
  # region grab
  grim -g "$(slurp)" "$FILE"
else
  # full-screen
  grim "$FILE"
fi

# ▶️ COPY TO CLIPBOARD?
if [ "$2" = "copy" ]; then
  wl-copy < "$FILE"
fi

# ▶️ NOTIFY
notify-send "Screenshot saved" "$FILE"
