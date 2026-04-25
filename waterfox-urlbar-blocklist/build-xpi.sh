#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
DIST_DIR="$SCRIPT_DIR/dist"
OUTPUT_FILE="$DIST_DIR/waterfox-urlbar-blocklist.xpi"

mkdir -p "$DIST_DIR"
rm -f "$OUTPUT_FILE"

(
  cd "$SCRIPT_DIR"
  bsdtar --format=zip -cf "$OUTPUT_FILE" manifest.json background.js options.html options.js options.css README.md
)

echo "Built $OUTPUT_FILE"
