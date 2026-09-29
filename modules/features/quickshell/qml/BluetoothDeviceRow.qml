import QtQuick
import QtQuick.Layouts


// A row in bluetooth device list
// Refernced by Bluetooth.qml

ColumnLayout {
    id: root
    spacing: 2

    property var device: null
    property bool expanded: false

    Theme { id: theme }

    function primaryLabel() {
        if (!root.device) return ""
        if (root.device.connected) return "disconnect"
        if (root.device.bonded) return "connect"
        if (root.device.pairing) return "pairing…"
        return "pair"
    }

    function primaryAction() {
        if (!root.device) return
        if (root.device.connected) root.device.disconnect()
        else if (root.device.bonded) root.device.connect()
        else {
            if (root.device.adapter) root.device.adapter.discovering = false
            root.device.pair()
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
            text: (root.device && root.device.connected ? "● " : "") + (root.device ? root.device.name : "")
            elide: Text.ElideRight
            color: root.device && root.device.connected ? theme.bright : theme.mid
            font.family: "JetBrains Mono"
            font.pixelSize: 12
            Layout.fillWidth: true
        }

        Text {
            visible: root.device && root.device.bonded
            text: root.expanded ? "hide" : "info"
            color: theme.dim
            font.family: "JetBrains Mono"
            font.pixelSize: 11

            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                cursorShape: Qt.PointingHandCursor
                onClicked: root.expanded = !root.expanded
            }
        }

        Text {
            text: root.primaryLabel()
            color: root.device && root.device.connected ? theme.red : theme.bright
            font.family: "JetBrains Mono"
            font.pixelSize: 11

            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                cursorShape: Qt.PointingHandCursor
                onClicked: root.primaryAction()
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 8
        visible: root.expanded
        spacing: 2

        Text {
            text: "Address  " + (root.device ? root.device.address : "")
            color: theme.dim
            font.family: "JetBrains Mono"
            font.pixelSize: 11
        }

        Text {
            visible: root.device && root.device.batteryAvailable
            text: "Battery  " + (root.device ? Math.round(root.device.battery * 100) : 0) + "%"
            color: theme.dim
            font.family: "JetBrains Mono"
            font.pixelSize: 11
        }

        Text {
            text: "Trusted  " + (root.device && root.device.trusted ? "yes" : "no")
            color: theme.dim
            font.family: "JetBrains Mono"
            font.pixelSize: 11
        }

        Text {
            text: "unpair"
            color: theme.red
            font.family: "JetBrains Mono"
            font.pixelSize: 11

            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                cursorShape: Qt.PointingHandCursor
                onClicked: if (root.device) root.device.forget()
            }
        }
    }
}
