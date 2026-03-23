#!/usr/bin/env bash

set -euo pipefail

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

wg_run_privileged() {
  if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
    "$@"
  else
    sudo "$@"
  fi
}

wg_set_context() {
  CONFIG="$1"
  INTERFACE=$(basename "$CONFIG" .conf)
  STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/wireguard-fallback"
  RUNTIME_CONFIG="$STATE_DIR/${INTERFACE}.conf"
  RESOLVCONF_BACKUP="$STATE_DIR/${INTERFACE}.resolv.conf.bak"
}

wg_fix_config_permissions() {
  chmod 600 "$CONFIG" 2>/dev/null || true
}

wg_config_has_dns() {
  awk '
    /^\[Interface\]/ { in_interface = 1; next }
    /^\[/ { in_interface = 0 }
    in_interface && /^[[:space:]]*DNS[[:space:]]*=/ { found = 1 }
    END { exit(found ? 0 : 1) }
  ' "$CONFIG"
}

wg_resolvconf_needs_fallback() {
  local resolvconf_bin resolved_target

  if ! resolvconf_bin=$(command -v resolvconf 2>/dev/null); then
    return 0
  fi

  resolved_target=$(readlink -f "$resolvconf_bin" 2>/dev/null || printf '%s\n' "$resolvconf_bin")
  if [[ "$resolved_target" == */resolvectl ]]; then
    systemctl is-active --quiet systemd-resolved || return 0
  fi

  return 1
}

wg_needs_dns_fallback() {
  wg_config_has_dns && wg_resolvconf_needs_fallback
}

wg_prepare_runtime_config() {
  install -d -m 700 "$STATE_DIR"
  awk '
    /^\[Interface\]/ { in_interface = 1; print; next }
    /^\[/ { in_interface = 0 }
    !(in_interface && /^[[:space:]]*DNS[[:space:]]*=/) { print }
  ' "$CONFIG" >"$RUNTIME_CONFIG"
  chmod 600 "$RUNTIME_CONFIG"
}

wg_effective_config() {
  if wg_needs_dns_fallback; then
    wg_prepare_runtime_config
    printf '%s\n' "$RUNTIME_CONFIG"
  else
    printf '%s\n' "$CONFIG"
  fi
}

wg_apply_dns_fallback() {
  local dns_entries tmp_file
  local -a nameservers=()
  local -a search_domains=()

  if ! wg_needs_dns_fallback; then
    return 0
  fi

  mapfile -t dns_entries < <(
    awk '
      /^\[Interface\]/ { in_interface = 1; next }
      /^\[/ { in_interface = 0 }
      in_interface && /^[[:space:]]*DNS[[:space:]]*=/ {
        sub(/^[[:space:]]*DNS[[:space:]]*=[[:space:]]*/, "")
        gsub(/,/, " ")
        print
      }
    ' "$CONFIG" \
      | tr ' ' '\n' \
      | sed '/^$/d'
  )

  if [[ ${#dns_entries[@]} -eq 0 ]]; then
    return 0
  fi

  for entry in "${dns_entries[@]}"; do
    if [[ "$entry" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ || "$entry" == *:* ]]; then
      nameservers+=("$entry")
    else
      search_domains+=("$entry")
    fi
  done

  wg_run_privileged install -d -m 700 "$STATE_DIR"
  wg_run_privileged cp /etc/resolv.conf "$RESOLVCONF_BACKUP"

  tmp_file=$(mktemp)
  {
    printf '# Added by vpn-up.sh for %s\n' "$INTERFACE"
    for ns in "${nameservers[@]}"; do
      printf 'nameserver %s\n' "$ns"
    done
    if [[ ${#search_domains[@]} -gt 0 ]]; then
      printf 'search %s\n' "${search_domains[*]}"
    fi
    cat "$RESOLVCONF_BACKUP"
  } | awk '!seen[$0]++' >"$tmp_file"

  wg_run_privileged install -m 644 "$tmp_file" /etc/resolv.conf
  rm -f "$tmp_file"
}

wg_restore_dns_fallback() {
  if [[ -f "$RESOLVCONF_BACKUP" ]]; then
    wg_run_privileged cp "$RESOLVCONF_BACKUP" /etc/resolv.conf
    wg_run_privileged rm -f "$RESOLVCONF_BACKUP"
  fi

  rm -f "$RUNTIME_CONFIG"
}
