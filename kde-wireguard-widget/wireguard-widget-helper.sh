#!/usr/bin/env bash
set -euo pipefail

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SCRIPTS_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
USER_HOME=$(cd "$SCRIPT_DIR/../.." && pwd)
DEFAULT_VPN_DIR="$USER_HOME/work/vpn"
VPN_DIR=""

usage() {
  cat <<'EOF'
Usage:
  wireguard-widget-helper.sh [--vpn-dir <path>] status
  wireguard-widget-helper.sh [--vpn-dir <path>] up <config.conf>
  wireguard-widget-helper.sh [--vpn-dir <path>] down [config.conf]
EOF
}

normalize_vpn_dir() {
  local dir="${1:-}"

  if [[ -z "$dir" ]]; then
    printf '%s\n' "$DEFAULT_VPN_DIR"
    return 0
  fi

  if [[ "$dir" == "~" ]]; then
    dir="$USER_HOME"
  elif [[ "$dir" == "~/"* ]]; then
    dir="$USER_HOME/${dir:2}"
  elif [[ "$dir" != /* ]]; then
    dir="$USER_HOME/$dir"
  fi

  printf '%s\n' "$dir"
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
  local command

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --vpn-dir)
        [[ $# -ge 2 ]] || {
          usage >&2
          exit 1
        }

        VPN_DIR=$(normalize_vpn_dir "$2")
        shift 2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        break
        ;;
    esac
  done

  VPN_DIR="${VPN_DIR:-$DEFAULT_VPN_DIR}"
  command="${1:-}"

  case "$command" in
    status)
      print_status
      ;;
    up)
      [[ $# -eq 2 ]] || {
        usage >&2
        exit 1
      }

      run_as_root --vpn-dir "$VPN_DIR" up-root "$2"
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
        run_as_root --vpn-dir "$VPN_DIR" down-root "$2"
      else
        run_as_root --vpn-dir "$VPN_DIR" down-root
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
