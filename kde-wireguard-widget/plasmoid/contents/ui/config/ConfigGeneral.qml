import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs as QtDialogs

import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid

KCM.SimpleKCM {
    id: root

    property string cfg_vpnConfigDir: Plasmoid.configuration.vpnConfigDir

    function pathFromUrl(url) {
        let value = url.toString()
        if (value.startsWith("file://")) {
            value = value.slice(7)
        }
        return decodeURIComponent(value)
    }

    Kirigami.FormLayout {
        anchors.fill: parent

        RowLayout {
            Layout.fillWidth: true
            Kirigami.FormData.label: "VPN config dir:"

            TextField {
                id: vpnDirField
                Layout.fillWidth: true
                placeholderText: "~/work/vpn"
                text: root.cfg_vpnConfigDir

                onTextChanged: root.cfg_vpnConfigDir = text.trim()
            }

            Button {
                icon.name: "document-open"
                text: "Browse"
                onClicked: folderDialog.open()
            }
        }

        RowLayout {
            Layout.fillWidth: true

            Item {
                Layout.fillWidth: true
            }

            Button {
                text: "Use Default"
                onClicked: vpnDirField.text = ""
            }
        }

        Label {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            text: root.cfg_vpnConfigDir.length > 0
                ? "The widget will read WireGuard configs from: " + root.cfg_vpnConfigDir
                : "Default path is ~/work/vpn. Leave this empty to keep using that default."
        }
    }

    QtDialogs.FolderDialog {
        id: folderDialog
        title: "Select VPN config directory"

        onAccepted: {
            vpnDirField.text = root.pathFromUrl(selectedFolder)
        }
    }
}
