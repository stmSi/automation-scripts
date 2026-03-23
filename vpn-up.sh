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

# 1) Tear down if already up
if ip link show "$INTERFACE" &>/dev/null; then
  echo "🛑 Bringing down existing $INTERFACE..."
  wg_run_privileged wg-quick down "$(wg_effective_config)"
  wg_restore_dns_fallback
fi

# 2) Remove any stale routes on that interface
echo "🧹 Cleaning stale routes for $INTERFACE..."
# use awk instead of grep so we don’t get a non-zero exit if there are no matches
ip route show \
  | awk -v ifc="$INTERFACE" '$0 ~ " dev " ifc { print $0 }' \
  | while IFS= read -r ROUTE; do
    echo "   • deleting: $ROUTE"
    wg_run_privileged ip route del $ROUTE
  done

# 3) Bring the new tunnel up
echo "🚀 Bringing up $INTERFACE..."
if wg_needs_dns_fallback; then
  echo "⚙️  Using manual DNS fallback because systemd-resolved is not active."
fi

wg_run_privileged wg-quick up "$(wg_effective_config)"
wg_apply_dns_fallback

echo "✅ Tunnel $INTERFACE is up."
