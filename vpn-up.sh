#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <wg-config.conf>"
  exit 1
fi

CONFIG="$1"
INTERFACE=$(basename "$CONFIG" .conf)

# 1) Tear down if already up
if ip link show "$INTERFACE" &>/dev/null; then
  echo "🛑 Bringing down existing $INTERFACE..."
  sudo wg-quick down "$CONFIG"
fi

# 2) Remove any stale routes on that interface
echo "🧹 Cleaning stale routes for $INTERFACE..."
# use awk instead of grep so we don’t get a non-zero exit if there are no matches
ip route show \
  | awk -v ifc="$INTERFACE" '$0 ~ " dev " ifc { print $0 }' \
  | while IFS= read -r ROUTE; do
    echo "   • deleting: $ROUTE"
    sudo ip route del $ROUTE
  done

# 3) Bring the new tunnel up
echo "🚀 Bringing up $INTERFACE..."
sudo wg-quick up "$CONFIG"

echo "✅ Tunnel $INTERFACE is up."

