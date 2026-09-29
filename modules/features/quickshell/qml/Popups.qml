import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts

// Transient toast stack, top-right, auto-dismiss after 5s
PanelWindow {
    id: popups
    required property var model

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "notification-popups"
    exclusiveZone: 0

    anchors {
        top: true
        right: true
    }

    margins.top: 10
    margins.right: 10

    implicitWidth: 300
    implicitHeight: col.implicitHeight
    color: "transparent"
    visible: popups.model.count > 0

    Theme { id: theme }

    ColumnLayout {
        id: col
        width: parent.width
        spacing: 6

        Repeater {
            model: popups.model

            Rectangle {
                id: toast
                required property var modelData
		required property int index
                readonly property bool critical: modelData.notifObj.urgency === NotificationUrgency.Critical
                readonly property bool low: modelData.notifObj.urgency === NotificationUrgency.Low
                Layout.fillWidth: true
                implicitHeight: toastCol.implicitHeight + 16
                radius: 4
                color: Qt.rgba(theme.bg.r, theme.bg.g, theme.bg.b, 0.95)
                border.width: 1
                border.color: critical ? theme.red : Qt.rgba(theme.fg.r, theme.fg.g, theme.fg.b, 0.15)

                // urgency stripe
                Rectangle {
                    visible: toast.critical
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 3
                    radius: 2
                    color: theme.red
                }

                ColumnLayout {
                    id: toastCol
                    anchors.fill: parent
                    anchors.margins: 8
                    anchors.leftMargin: 12
                    spacing: 2

                    Text {
                        text: toast.modelData.notifObj.summary
                        color: toast.critical ? theme.red
                             : toast.low ? theme.mid : theme.fg
                        font.family: "JetBrains Mono"
                        font.pixelSize: 13
                        font.bold: true
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Text {
                        visible: toast.modelData.notifObj.body.length > 0
                        text: toast.modelData.notifObj.body
                        color: toast.low ? theme.dim : theme.mid
                        font.family: "JetBrains Mono"
                        font.pixelSize: 12
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                   // hide the toast only; the notification stays tracked, so it stays in the center
                   MouseArea {
                       anchors.fill: parent
                       cursorShape: Qt.PointingHandCursor
                       onClicked: popups.model.remove(toast.index)
                   }
                }
            }
        }
    }
}
