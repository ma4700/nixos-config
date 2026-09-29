import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts

// Toggleable history panel.
PanelWindow {
    id: panel
    required property var server
    property var expandedId: null
    signal closeRequested()

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "notification-center"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusiveZone: 0

    // covers the whole screen so a click anywhere outside the box closes it
    anchors {
        top: true
        right: true
        bottom: true
        left: true
    }

    color: "transparent"

    Theme { id: theme }

    onVisibleChanged: if (!visible) expandedId = null

    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: panel.closeRequested()
    }

    MouseArea {
        anchors.fill: parent
        onClicked: panel.closeRequested()
    }

    Rectangle {
        id: box
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 10
        anchors.rightMargin: 10

        width: 320
        height: Math.max(60, Math.min(420, contentCol.implicitHeight + 24))
        radius: 4
        color: Qt.rgba(theme.bg.r, theme.bg.g, theme.bg.b, 0.92)

        // swallows clicks so they don't fall through to the fullscreen closer above
        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        ColumnLayout {
            id: contentCol
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "Notifications"
                    color: theme.fg
                    font.family: "JetBrains Mono"
                    font.pixelSize: 14
                    font.bold: true
                    Layout.fillWidth: true
                }

                Text {
                    text: "clear"
                    color: theme.mid
                    font.family: "JetBrains Mono"
                    font.pixelSize: 12

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            // copy first: dismiss() removes items from the live list mid-loop
                            const all = server.trackedNotifications.values.slice()
                            for (const n of all)
                              n.dismiss()
                        }
                    }
                }
            }

            Text {
                visible: panel.server.trackedNotifications.values.length === 0
                text: "No notifications"
                color: theme.dim
                font.family: "JetBrains Mono"
                font.pixelSize: 13
            }

            ListView {
                id: list
                Layout.fillWidth: true
                implicitHeight: Math.min(contentHeight, 320)
                clip: true
                spacing: 6
                model: panel.server.trackedNotifications.values

                delegate: Rectangle {
                    id: entry
                    required property var modelData
                    readonly property bool expanded: panel.expandedId === entry.modelData.id
                    readonly property bool critical: entry.modelData.urgency === NotificationUrgency.Critical
                    readonly property bool low: entry.modelData.urgency === NotificationUrgency.Low
                    width: list.width
                    implicitHeight: col.implicitHeight + 16
                    radius: 4
                    color: critical ? Qt.rgba(theme.red.r, theme.red.g, theme.red.b, 0.14)
                                    : Qt.rgba(theme.fg.r, theme.fg.g, theme.fg.b, 0.06)

                    // urgency stripe
                    Rectangle {
                        visible: entry.critical
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 3
                        radius: 2
                        color: theme.red
                    }

                    // toggles expand/collapse, sits under the "x" so that still dismisses on its own
                    MouseArea {
                        anchors.fill: parent
                        onClicked: panel.expandedId = entry.expanded ? null : entry.modelData.id
                    }

                    ColumnLayout {
                        id: col
                        anchors.fill: parent
                        anchors.margins: 8
                        anchors.leftMargin: 12
                        spacing: 2

                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: entry.modelData.summary
                                color: entry.critical ? theme.red
                                     : entry.low ? theme.mid : theme.fg
                                font.family: "JetBrains Mono"
                                font.pixelSize: 13
                                font.bold: true
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                maximumLineCount: entry.expanded ? 10 : 1
                                wrapMode: entry.expanded ? Text.Wrap : Text.NoWrap
                            }

                            Text {
                                text: "x"
                                color: theme.mid
                                font.family: "JetBrains Mono"
                                font.pixelSize: 13

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: entry.modelData.dismiss()
                                }
                            }
                        }

                        Text {
                            visible: entry.modelData.body.length > 0
                            text: entry.modelData.body
                            color: entry.low ? theme.dim : theme.mid
                            font.family: "JetBrains Mono"
                            font.pixelSize: 12
                            wrapMode: Text.Wrap
                            elide: Text.ElideRight
                            maximumLineCount: entry.expanded ? 20 : 2
                            Layout.fillWidth: true
                        }
                    }
                }
            }
        }
    }
}
