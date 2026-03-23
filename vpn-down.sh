#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/wireguard-common.sh"

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <wg-config.conf>"
  exit 1
fi

wg_set_context "$1"
wg_fix_config_permissions

echo "🛑 Tearing down $INTERFACE..."
if ip link show "$INTERFACE" &>/dev/null; then
  wg_run_privileged wg-quick down "$(wg_effective_config)"
else
  echo "ℹ️  $INTERFACE is already down."
fi

wg_restore_dns_fallback

echo "🧹 Removing any leftover routes for $INTERFACE..."
ip route show \
  | awk -v ifc="$INTERFACE" '$0 ~ " dev " ifc { print $0 }' \
  | while IFS= read -r ROUTE; do
      echo "   • deleting: $ROUTE"
      wg_run_privileged ip route del $ROUTE
    done

echo "✅ Tunnel $INTERFACE is down."
