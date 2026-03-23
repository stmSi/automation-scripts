# KDE WireGuard Widget

Local Plasma 6 widget for switching between WireGuard configs in `~/work/vpn`.

## Files

- `plasmoid/`: widget source package
- `wireguard-widget-helper.sh`: helper used by the widget
- `install.sh`: install or upgrade the widget and add it to the first panel

## Install

Run:

```bash
~/scripts/kde-wireguard-widget/install.sh
```

The script will:

- install or upgrade the `com.stm.wireguardswitcher` plasmoid
- add it to your first Plasma panel if it is not already there

## Notes

- The widget reads `~/work/vpn/*.conf`
- Connect and disconnect actions use `pkexec`, so KDE should show an authentication prompt
- Re-running `install.sh` is the update command too
