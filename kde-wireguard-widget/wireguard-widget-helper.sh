#!/usr/bin/env bash
set -euo pipefail

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SCRIPTS_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
VPN_DIR="${WIREGUARD_VPN_DIR:-$HOME/work/vpn}"

usage() {
  cat <<'EOF'
Usage:
  wireguard-widget-helper.sh status
  wireguard-widget-helper.sh up <config.conf>
  wireguard-widget-helper.sh down [config.conf]
EOF
}

collect_configs() {
  local config

  shopt -s nullglob
  for config in "$VPN_DIR"/*.conf; do
    printf '%s\n' "$(basename "$config")"
  done
  shopt -u nullglob
}

resolve_config() {
  local requested="$1"
  local candidate

  candidate=$(basename "$requested")
  if [[ -z "$candidate" || "$candidate" == "." || "$candidate" == ".." ]]; then
    echo "Invalid config: $requested" >&2
    exit 1
  fi

  candidate="$VPN_DIR/$candidate"
  if [[ ! -f "$candidate" ]]; then
    echo "Config not found: $requested" >&2
    exit 1
  fi

  printf '%s\n' "$candidate"
}

interface_for_config() {
  basename "$1" .conf
}

config_is_active() {
  local config="$1"
  local interface

  interface=$(interface_for_config "$config")
  ip link show "$interface" &>/dev/null
}

print_status() {
  local config
  local interface
  local active

  while IFS= read -r config; do
    interface=$(interface_for_config "$config")
    active=0
    if config_is_active "$config"; then
      active=1
    fi
    printf '%s\t%s\t%s\t%s\n' "$config" "$interface" "$interface" "$active"
  done < <(collect_configs | sort)
}

run_as_root() {
  if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
    "$0" "$@"
  else
    exec pkexec "$0" "$@"
  fi
}

bring_up() {
  local target_config="$1"
  local config
  local target_path

  target_path=$(resolve_config "$target_config")

  while IFS= read -r config; do
    if [[ "$config" != "$target_config" ]] && config_is_active "$config"; then
      "$SCRIPTS_DIR/vpn-down.sh" "$(resolve_config "$config")"
    fi
  done < <(collect_configs)

  "$SCRIPTS_DIR/vpn-up.sh" "$target_path"
}

bring_down() {
  local target_config="${1:-}"
  local config

  if [[ -n "$target_config" ]]; then
    "$SCRIPTS_DIR/vpn-down.sh" "$(resolve_config "$target_config")"
    return 0
  fi

  while IFS= read -r config; do
    if config_is_active "$config"; then
      "$SCRIPTS_DIR/vpn-down.sh" "$(resolve_config "$config")"
    fi
  done < <(collect_configs)
}

main() {
  local command="${1:-}"

  case "$command" in
    status)
      print_status
      ;;
    up)
      [[ $# -eq 2 ]] || {
        usage >&2
        exit 1
      }

      run_as_root up-root "$2"
      ;;
    up-root)
      [[ $# -eq 2 ]] || {
        usage >&2
        exit 1
      }

      bring_up "$2"
      ;;
    down)
      if [[ $# -gt 2 ]]; then
        usage >&2
        exit 1
      fi

      if [[ $# -eq 2 ]]; then
        run_as_root down-root "$2"
      else
        run_as_root down-root
      fi
      ;;
    down-root)
      if [[ $# -gt 2 ]]; then
        usage >&2
        exit 1
      fi

      if [[ $# -eq 2 ]]; then
        bring_down "$2"
      else
        bring_down
      fi
      ;;
    *)
      usage >&2
      exit 1
      ;;
  esac
}

main "$@"
