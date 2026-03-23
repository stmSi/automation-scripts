pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root

    readonly property string helperScript: "/home/stm/scripts/kde-wireguard-widget/wireguard-widget-helper.sh"
    property bool busy: false
    property bool anyActive: false
    property string activeSummary: ""
    property string infoMessage: ""
    property string errorMessage: ""

    Plasmoid.title: "WireGuard Switcher"
    Plasmoid.icon: anyActive ? "network-vpn" : "network-offline"
    Plasmoid.status: anyActive ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.PassiveStatus
    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground

    preferredRepresentation: Plasmoid.formFactor === PlasmaCore.Types.Planar ? fullRepresentation : compactRepresentation
    toolTipMainText: anyActive ? "WireGuard connected" : "WireGuard disconnected"
    toolTipSubText: activeSummary.length > 0 ? activeSummary : "~/work/vpn"

    ListModel {
        id: vpnModel
    }

    function quoteArg(arg) {
        return "'" + String(arg).replace(/'/g, "'\\''") + "'"
    }

    function commandFor(args) {
        const fullCommand = [root.helperScript].concat(args).map(root.quoteArg).join(" ")
        return "/bin/sh -lc " + root.quoteArg(fullCommand)
    }

    function extractText(data, keys) {
        for (const key of keys) {
            if (data[key] !== undefined && data[key] !== null) {
                return String(data[key])
            }
        }

        return ""
    }

    function extractNumber(data, keys, fallbackValue) {
        for (const key of keys) {
            if (data[key] !== undefined && data[key] !== null && data[key] !== "") {
                return Number(data[key])
            }
        }

        return fallbackValue
    }

    function applyStatusOutput(stdoutText) {
        const rows = stdoutText.trim().length > 0 ? stdoutText.trim().split(/\n+/) : []
        let activeInterfaces = []

        vpnModel.clear()
        for (const row of rows) {
            const fields = row.split("\t")
            if (fields.length < 4) {
                continue
            }

            const active = fields[3] === "1"
            vpnModel.append({
                filename: fields[0],
                interfaceName: fields[1],
                displayName: fields[2],
                active: active
            })

            if (active) {
                activeInterfaces.push(fields[2])
            }
        }

        anyActive = activeInterfaces.length > 0
        activeSummary = activeInterfaces.length > 0 ? activeInterfaces.join(", ") : "No active tunnel"
    }

    function refreshStatus() {
        statusSource.run(commandFor(["status"]))
    }

    function connectConfig(filename) {
        errorMessage = ""
        infoMessage = "Connecting " + filename + "..."
        busy = true
        actionSource.run(commandFor(["up", filename]))
    }

    function disconnectConfig(filename) {
        errorMessage = ""
        infoMessage = "Disconnecting " + filename + "..."
        busy = true
        actionSource.run(commandFor(["down", filename]))
    }

    function disconnectAll() {
        errorMessage = ""
        infoMessage = "Disconnecting active tunnels..."
        busy = true
        actionSource.run(commandFor(["down"]))
    }

    function hasResultPayload(data) {
        return data["stdout"] !== undefined
            || data["stderr"] !== undefined
            || data["exit code"] !== undefined
            || data["exitCode"] !== undefined
            || data["standard output"] !== undefined
            || data["standard error"] !== undefined
            || data["out"] !== undefined
            || data["err"] !== undefined
    }

    compactRepresentation: Item {
        implicitWidth: Kirigami.Units.iconSizes.medium + Kirigami.Units.smallSpacing * 4
        implicitHeight: implicitWidth

        Kirigami.Icon {
            anchors.centerIn: parent
            width: Kirigami.Units.iconSizes.medium
            height: width
            source: Plasmoid.icon
        }

        Rectangle {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Kirigami.Units.smallSpacing
            width: Kirigami.Units.smallSpacing * 2
            height: width
            radius: width / 2
            color: root.anyActive ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.disabledTextColor
            border.color: Kirigami.Theme.backgroundColor
            border.width: 1
        }

        QQC2.BusyIndicator {
            anchors.centerIn: parent
            running: root.busy
            visible: running
            width: Kirigami.Units.iconSizes.medium + Kirigami.Units.smallSpacing * 2
            height: width
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.expanded = !root.expanded
        }
    }

    fullRepresentation: Item {
        implicitWidth: Kirigami.Units.gridUnit * 22
        implicitHeight: Math.max(Kirigami.Units.gridUnit * 14, contentLayout.implicitHeight + Kirigami.Units.largeSpacing * 2)

        ColumnLayout {
            id: contentLayout

            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.largeSpacing

            RowLayout {
                Layout.fillWidth: true

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing / 2

                    PlasmaComponents3.Label {
                        Layout.fillWidth: true
                        text: "WireGuard"
                        font.bold: true
                    }

                    PlasmaComponents3.Label {
                        Layout.fillWidth: true
                        color: root.anyActive ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.disabledTextColor
                        elide: Text.ElideRight
                        text: root.activeSummary
                    }
                }

                PlasmaComponents3.ToolButton {
                    enabled: !root.busy
                    icon.name: "view-refresh"
                    text: "Refresh"
                    onClicked: root.refreshStatus()
                }
            }

            QQC2.BusyIndicator {
                Layout.alignment: Qt.AlignHCenter
                running: root.busy
                visible: running
            }

            Kirigami.PlaceholderMessage {
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 5
                visible: vpnModel.count === 0 && !root.busy
                text: "No WireGuard configs found in ~/work/vpn"
            }

            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: Kirigami.Units.gridUnit * 8
                Layout.preferredHeight: Math.min(contentHeight, Kirigami.Units.gridUnit * 12)
                clip: true
                model: vpnModel
                spacing: Kirigami.Units.smallSpacing

                delegate: Rectangle {
                    required property bool active
                    required property string displayName
                    required property string filename
                    required property string interfaceName

                    width: ListView.view.width
                    height: delegateLayout.implicitHeight + Kirigami.Units.smallSpacing * 2
                    radius: Kirigami.Units.smallSpacing
                    color: active
                        ? Qt.rgba(Kirigami.Theme.positiveTextColor.r, Kirigami.Theme.positiveTextColor.g, Kirigami.Theme.positiveTextColor.b, 0.12)
                        : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05)
                    border.color: active ? Kirigami.Theme.positiveTextColor : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12)
                    border.width: 1

                    RowLayout {
                        id: delegateLayout

                        anchors.fill: parent
                        anchors.margins: Kirigami.Units.smallSpacing
                        spacing: Kirigami.Units.smallSpacing

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Kirigami.Units.smallSpacing / 2

                            PlasmaComponents3.Label {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                font.bold: active
                                text: displayName
                            }

                            PlasmaComponents3.Label {
                                Layout.fillWidth: true
                                color: Kirigami.Theme.disabledTextColor
                                elide: Text.ElideRight
                                text: filename
                            }
                        }

                        PlasmaComponents3.Button {
                            enabled: !root.busy && !active
                            text: "Connect"
                            visible: !active
                            onClicked: root.connectConfig(filename)
                        }

                        PlasmaComponents3.Button {
                            enabled: !root.busy && active
                            text: "Disconnect"
                            visible: active
                            onClicked: root.disconnectConfig(filename)
                        }
                    }
                }
            }

            PlasmaComponents3.Button {
                Layout.alignment: Qt.AlignRight
                enabled: !root.busy && root.anyActive
                text: "Disconnect All"
                onClicked: root.disconnectAll()
            }

            PlasmaComponents3.Label {
                Layout.fillWidth: true
                color: Kirigami.Theme.negativeTextColor
                text: root.errorMessage
                visible: text.length > 0
                wrapMode: Text.Wrap
            }

            PlasmaComponents3.Label {
                Layout.fillWidth: true
                color: Kirigami.Theme.disabledTextColor
                text: root.infoMessage
                visible: text.length > 0 && root.errorMessage.length === 0
                wrapMode: Text.Wrap
            }
        }
    }

    Plasma5Support.DataSource {
        id: statusSource
        engine: "executable"

        function run(command) {
            disconnectSource(command)
            connectSource(command)
        }

        onNewData: function(sourceName, data) {
            if (!root.hasResultPayload(data)) {
                return
            }

            const stdoutText = root.extractText(data, ["stdout", "standard output", "out"])
            const stderrText = root.extractText(data, ["stderr", "standard error", "err"])
            const exitCode = root.extractNumber(data, ["exit code", "exitCode"], 0)

            disconnectSource(sourceName)
            if (exitCode === 0) {
                root.errorMessage = ""
                root.applyStatusOutput(stdoutText)
                if (!root.busy) {
                    root.infoMessage = root.anyActive ? "Active tunnel: " + root.activeSummary : "No active tunnel"
                }
            } else {
                root.errorMessage = stderrText.length > 0 ? stderrText : "Failed to read WireGuard status."
            }
        }
    }

    Plasma5Support.DataSource {
        id: actionSource
        engine: "executable"

        function run(command) {
            disconnectSource(command)
            connectSource(command)
        }

        onNewData: function(sourceName, data) {
            if (!root.hasResultPayload(data)) {
                return
            }

            const stdoutText = root.extractText(data, ["stdout", "standard output", "out"])
            const stderrText = root.extractText(data, ["stderr", "standard error", "err"])
            const exitCode = root.extractNumber(data, ["exit code", "exitCode"], 0)

            disconnectSource(sourceName)
            root.busy = false
            if (exitCode === 0) {
                root.errorMessage = ""
                root.infoMessage = stdoutText.length > 0 ? stdoutText.trim() : "WireGuard command completed."
            } else {
                root.errorMessage = stderrText.length > 0 ? stderrText.trim() : "WireGuard command failed."
                root.infoMessage = stdoutText.trim()
            }

            root.refreshStatus()
        }
    }

    Timer {
        interval: 5000
        repeat: true
        running: root.expanded
        onTriggered: root.refreshStatus()
    }

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: "Refresh"
            icon.name: "view-refresh"
            onTriggered: root.refreshStatus()
        },
        PlasmaCore.Action {
            text: "Disconnect All"
            icon.name: "network-disconnect"
            enabled: root.anyActive && !root.busy
            onTriggered: root.disconnectAll()
        }
    ]

    onExpandedChanged: function() {
        if (root.expanded) {
            refreshStatus()
        }
    }

    Component.onCompleted: refreshStatus()
}
