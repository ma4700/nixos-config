import QtQuick
import QtQuick.Layouts
import qs

// Network section: connection type and its details
ColumnLayout {
    id: root

    required property var net

    spacing: 8

    Theme { id: theme }

    Text {
        text: "Network"
        color: theme.fg
        font.family: "JetBrains Mono"
        font.pixelSize: 14
        font.bold: true
        Layout.fillWidth: true
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: info.implicitHeight + 16
        radius: 4
        color: Qt.rgba(theme.fg.r, theme.fg.g, theme.fg.b, 0.06)

        ColumnLayout {
            id: info
            anchors.fill: parent
            anchors.margins: 8
            spacing: 4

            Text {
                text: root.net.kind === "wifi" ? "Wi-Fi"
                    : root.net.kind === "ethernet" ? "Ethernet"
                    : "Not connected"
                color: root.net.kind === "none" ? theme.red : theme.fg
                font.family: "JetBrains Mono"
                font.pixelSize: 13
                font.bold: true
            }

            Text {
                visible: root.net.kind === "none"
                text: "No active connection"
                color: theme.mid
                font.family: "JetBrains Mono"
                font.pixelSize: 12
            }

            InfoRows {
                Layout.fillWidth: true
                visible: root.net.rows.length > 0
                rows: root.net.rows
                labelWidth: 78
            }
        }
    }
}
