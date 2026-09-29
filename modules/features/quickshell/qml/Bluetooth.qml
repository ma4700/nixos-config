import Quickshell
import Quickshell.Wayland
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts

// Bar icon: Bluetooth
// On hover: connection status
// On click: Bluetooth menu
Item {
    id: root

    Theme { id: theme }

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool powered: root.adapter ? root.adapter.enabled : false
    readonly property bool scanning: root.adapter ? root.adapter.discovering : false

    readonly property var connectedDevices: Bluetooth.devices.values.filter(d => d.connected)
    readonly property var knownDevices: Bluetooth.devices.values.filter(d => d.bonded && !d.connected)
    readonly property var availableDevices: Bluetooth.devices.values.filter(d => !d.bonded)

    property bool hoverShown: false
    property bool pinned: false
    property real iconX: 0
    property bool suppressHover: false
    readonly property bool shown: pinned || hoverShown

    implicitWidth: 14
    implicitHeight: 12

    onPoweredChanged: cv.requestPaint()

    function captureX() { iconX = root.mapToItem(null, root.width / 2, 0).x }

    function dismiss() {
        pinned = false
        hoverShown = false
        suppressHover = true
        suppressTimer.restart()
    }

    Timer {
        id: suppressTimer
        interval: 400
        onTriggered: root.suppressHover = false
    }

    Timer {
        id: scanStopTimer
        interval: 10000
        onTriggered: if (root.adapter) root.adapter.discovering = false
    }

    function refresh() {
        if (!root.adapter || !root.adapter.enabled) return
        root.adapter.discovering = true
        scanStopTimer.restart()
    }

    Canvas {
        id: cv
        anchors.fill: parent
        onPaint: {
            const ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            ctx.strokeStyle = root.powered ? theme.mid : theme.dim
            ctx.lineWidth = 1.3
            ctx.lineCap = "round"
            ctx.lineJoin = "round"
            ctx.beginPath()
            ctx.moveTo(7, 1)
            ctx.lineTo(11, 4)
            ctx.lineTo(7, 6)
            ctx.lineTo(11, 8)
            ctx.lineTo(7, 11)
            ctx.lineTo(7, 1)
            ctx.stroke()
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -6
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: {
            if (root.suppressHover) return
            root.captureX()
            root.hoverShown = true
        }
        onExited: root.hoverShown = false
        onClicked: {
            root.captureX()
            root.pinned = true
        }
    }

    Region { id: passThrough }

    PanelWindow {
        id: overlay
        visible: root.shown

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "bluetooth-info"
        WlrLayershell.keyboardFocus: root.pinned ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        exclusiveZone: 0

        anchors { top: true; right: true; bottom: true; left: true }
        color: "transparent"
        mask: root.pinned ? null : passThrough

        Keys.onEscapePressed: root.dismiss()

        MouseArea {
            anchors.fill: parent
            enabled: root.pinned
            onClicked: root.dismiss()
        }

        // hover tooltip
        Rectangle {
            visible: root.hoverShown && !root.pinned
            y: 10
            x: Math.max(10, Math.min(overlay.width - width - 10, root.iconX - width / 2))
            width: tip.implicitWidth + 24
            height: tip.implicitHeight + 16
            radius: 4
            color: Qt.rgba(theme.bg.r, theme.bg.g, theme.bg.b, 0.92)

            Text {
                id: tip
                anchors.fill: parent
                anchors.margins: 8
                text: !root.powered ? "Bluetooth off"
                    : root.connectedDevices.length > 0
                        ? root.connectedDevices.map(d => d.name).join(", ")
                        : "Not connected"
                color: theme.fg
                font.family: "JetBrains Mono"
                font.pixelSize: 12
            }
        }

        // click menu
        Rectangle {
            id: box
            visible: root.pinned
            y: 10
            x: Math.max(10, Math.min(overlay.width - width - 10, root.iconX - width / 2))
            width: 280
            height: Math.min(overlay.height - 40, menuCol.implicitHeight + 24)
            radius: 4
            color: Qt.rgba(theme.bg.r, theme.bg.g, theme.bg.b, 0.92)
            clip: true

            MouseArea { anchors.fill: parent; onClicked: {} }

            Flickable {
                anchors.fill: parent
                anchors.margins: 12
                contentWidth: width
                contentHeight: menuCol.implicitHeight
                clip: true

                ColumnLayout {
                    id: menuCol
                    width: parent.width
                    spacing: 10

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

                        Rectangle {
                            implicitWidth: 36
                            implicitHeight: 18
                            radius: 9
                            color: root.powered
                                ? Qt.rgba(theme.bright.r, theme.bright.g, theme.bright.b, 0.25)
                                : Qt.rgba(theme.fg.r, theme.fg.g, theme.fg.b, 0.1)

                            Rectangle {
                                width: 14; height: 14
                                radius: 7
                                y: 2
                                x: root.powered ? parent.width - width - 2 : 2
                                color: root.powered ? theme.bright : theme.dim
                                Behavior on x { NumberAnimation { duration: 100 } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (root.adapter) root.adapter.enabled = !root.adapter.enabled
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        visible: root.powered

                        Text {
                            text: root.scanning ? "Scanning…" : "Devices"
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
                                onClicked: root.refresh()
                            }
                        }
                    }

                    Text {
                        visible: !root.powered
                        text: "Turn on Bluetooth to see devices"
                        color: theme.dim
                        font.family: "JetBrains Mono"
                        font.pixelSize: 12
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: root.powered && (root.connectedDevices.length > 0 || root.knownDevices.length > 0)
                        spacing: 2

                        Text {
                            text: "Known"
                            color: theme.mid
                            font.family: "JetBrains Mono"
                            font.pixelSize: 11
                        }

                        Repeater {
                            model: root.connectedDevices.concat(root.knownDevices)

                            BluetoothDeviceRow {
                                required property var modelData
                                device: modelData
                                Layout.fillWidth: true
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: root.powered && root.availableDevices.length > 0
                        spacing: 2

                        Text {
                            text: "Available"
                            color: theme.mid
                            font.family: "JetBrains Mono"
                            font.pixelSize: 11
                        }

                        Repeater {
                            model: root.availableDevices

                            BluetoothDeviceRow {
                                required property var modelData
                                device: modelData
                                Layout.fillWidth: true
                            }
                        }
                    }

                    Text {
                        visible: root.powered && root.connectedDevices.length === 0
                            && root.knownDevices.length === 0 && root.availableDevices.length === 0
                        text: root.scanning ? "Looking for devices…" : "No devices found - try refresh"
                        color: theme.dim
                        font.family: "JetBrains Mono"
                        font.pixelSize: 12
                    }
                }
            }
        }
    }
}
