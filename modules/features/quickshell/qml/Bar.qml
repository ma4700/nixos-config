import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

// workspaces, window title, notification badge, clock
PanelWindow {
    id: bar
    required property var server
    signal toggleRequested()

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 38
    color: Qt.rgba(theme.bg.r, theme.bg.g, theme.bg.b, 0.8)

    Theme { id: theme }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 16

        Component {
            id: bluetoothIcon
            Bluetooth { }
        }        

        // workspaces
        RowLayout {
            spacing: 4

            Repeater {
                model: Hyprland.workspaces.values

                Item {
                    id: wsItem
                    required property var modelData
                    implicitWidth: 26
                    implicitHeight: 26

                    readonly property bool isActive: modelData.focused

                    Rectangle {
                        anchors.fill: parent
                        radius: 4
                        color: wsItem.isActive ? Qt.rgba(theme.fg.r, theme.fg.g, theme.fg.b, 0.12) : "transparent"
                    }

                    Text {
                        anchors.centerIn: parent
                        text: wsItem.modelData.id
                        font.family: "JetBrains Mono"
                        font.pixelSize: 14
                        font.bold: wsItem.isActive
                        color: wsItem.isActive ? theme.bright : theme.mid
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Hyprland.dispatch("workspace " + wsItem.modelData.id)
                    }
                }
            }
        }

        // window title
        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: ToplevelManager.activeToplevel?.title ?? ""
            font.family: "JetBrains Mono"
            font.pixelSize: 14
            color: theme.mid
        }

        // clock
        Text {
            id: clock
            font.family: "JetBrains Mono"
            font.pixelSize: 14
            color: theme.fg

            function update() {
                text = Qt.formatDateTime(new Date(), "HH:mm  ddd, MMM dd");
            }

            Component.onCompleted: update()

            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: clock.update()
            }
        }

	// network + bluetooth
	RowLayout {
	    spacing: 3
	    Network { }
	    Loader {
	        active: BluetoothFeature.enabled
	        sourceComponent: bluetoothIcon
	    }
	}        

	// audio
	Audio { }

	// keyboard layout
	KeyboardLayout { }

	// cpu, gpu, battery
	Vitals { }

        // notification count, click to toggle the center - rightmost item in the bar
        Item {
            id: notifBadge
            implicitWidth: notifText.implicitWidth + 12
            implicitHeight: 22

            readonly property int count: bar.server.trackedNotifications.values.length

            Rectangle {
                anchors.fill: parent
                radius: 4
                color: notifBadge.count > 0 ? Qt.rgba(theme.fg.r, theme.fg.g, theme.fg.b, 0.12) : "transparent"
            }

            Text {
                id: notifText
                anchors.centerIn: parent
                text: notifBadge.count > 0 ? notifBadge.count : "–"
                font.family: "JetBrains Mono"
                font.pixelSize: 13
                color: notifBadge.count > 0 ? theme.bright : theme.dim
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: bar.toggleRequested()
            }
        }
    }
}
