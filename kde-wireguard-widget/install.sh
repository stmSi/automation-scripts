#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PACKAGE_DIR="$SCRIPT_DIR/plasmoid"
PLUGIN_ID="com.stm.wireguardswitcher"

chmod +x "$SCRIPT_DIR/wireguard-widget-helper.sh"

if kpackagetool6 -t Plasma/Applet -s "$PLUGIN_ID" >/dev/null 2>&1; then
  kpackagetool6 -t Plasma/Applet -r "$PLUGIN_ID"
fi

kpackagetool6 -t Plasma/Applet -i "$PACKAGE_DIR"

qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
var panel = panels()[0];
var existing = panel.widgets(\"$PLUGIN_ID\");
if (existing.length === 0) {
    panel.addWidget(\"$PLUGIN_ID\");
}
print(panel.widgets(\"$PLUGIN_ID\").length);
" >/dev/null

echo "Installed $PLUGIN_ID from $PACKAGE_DIR"
echo "If the icon is not visible yet, open the panel's widget menu once or restart plasmashell."
