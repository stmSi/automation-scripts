#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <wg-config.conf>"
  exit 1
fi

CONFIG="$1"
INTERFACE=$(basename "$CONFIG" .conf)

echo "🛑 Tearing down $INTERFACE..."
sudo wg-quick down "$CONFIG"

echo "🧹 Removing any leftover routes for $INTERFACE..."
ip route show \
  | awk -v ifc="$INTERFACE" '$0 ~ " dev " ifc { print $0 }' \
  | while IFS= read -r ROUTE; do
      echo "   • deleting: $ROUTE"
      sudo ip route del $ROUTE
    done

echo "✅ Tunnel $INTERFACE is down."
