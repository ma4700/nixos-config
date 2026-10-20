import QtQuick
import QtQuick.Layouts
import qs

// Bluetooth section: power toggle, refresh, Known / Available devices
ColumnLayout {
    id: root

    required property var bt

    spacing: 10

    Theme { id: theme }

    RowLayout {
        Layout.fillWidth: true

        Text {
            text: "Bluetooth"
            color: theme.fg
            font.family: "JetBrains Mono"
            font.pixelSize: 14
            font.bold: true
            Layout.fillWidth: true
        }

        // power switch
        Rectangle {
            implicitWidth: 36
            implicitHeight: 18
            radius: 9
            color: root.bt.powered
                ? Qt.rgba(theme.bright.r, theme.bright.g, theme.bright.b, 0.25)
                : Qt.rgba(theme.fg.r, theme.fg.g, theme.fg.b, 0.1)

            Rectangle {
                width: 14; height: 14
                radius: 7
                y: 2
                x: root.bt.powered ? parent.width - width - 2 : 2
                color: root.bt.powered ? theme.bright : theme.dim
                Behavior on x { NumberAnimation { duration: 100 } }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.bt.togglePower()
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        visible: root.bt.powered

        Text {
            text: root.bt.scanning ? "Scanning…" : "Devices"
            color: theme.mid
            font.family: "JetBrains Mono"
            font.pixelSize: 12
            Layout.fillWidth: true
        }

        Text {
            text: "refresh"
            color: theme.mid
            font.family: "JetBrains Mono"
            font.pixelSize: 12

            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                cursorShape: Qt.PointingHandCursor
                onClicked: root.bt.refresh()
            }
        }
    }

    Text {
        visible: !root.bt.powered
        text: "Turn on Bluetooth to see devices"
        color: theme.dim
        font.family: "JetBrains Mono"
        font.pixelSize: 12
    }

    ColumnLayout {
        Layout.fillWidth: true
        visible: root.bt.powered && (root.bt.connectedDevices.length > 0 || root.bt.knownDevices.length > 0)
        spacing: 2

        Text {
            text: "Known"
            color: theme.mid
            font.family: "JetBrains Mono"
            font.pixelSize: 11
        }

        Repeater {
            model: root.bt.connectedDevices.concat(root.bt.knownDevices)

            BluetoothRow {
                required property var modelData
                device: modelData
                Layout.fillWidth: true
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        visible: root.bt.powered && root.bt.availableDevices.length > 0
        spacing: 2

        Text {
            text: "Available"
            color: theme.mid
            font.family: "JetBrains Mono"
            font.pixelSize: 11
        }

        Repeater {
            model: root.bt.availableDevices

            BluetoothRow {
                required property var modelData
                device: modelData
                Layout.fillWidth: true
            }
        }
    }

    Text {
        visible: root.bt.powered && root.bt.connectedDevices.length === 0
            && root.bt.knownDevices.length === 0 && root.bt.availableDevices.length === 0
        text: root.bt.scanning ? "Looking for devices…" : "No devices found - try refresh"
        color: theme.dim
        font.family: "JetBrains Mono"
        font.pixelSize: 12
    }
}
