import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs

// Network, Bluetooth, audio and CPU/RAM as one bar widget.
// Hover: a short summary. Click: the full panel; a click anywhere or Esc
// closes it.
//
// Files in this folder:
//   *State.qml    data (nmcli, BlueZ, PipeWire, /proc), no visuals
//   *Icon(s).qml  the icons in the bar
//   *Card.qml     one section of the panel each
//   Summary.qml   the hover tooltip
//   AudioChannel, BluetoothRow, InfoRows: pieces used by the cards
Item {
    id: root

    Theme { id: theme }

    NetworkState { id: netState; detailsWanted: root.pinned }
    BluetoothState { id: btState; enabled: BluetoothFeature.enabled }
    AudioState { id: audioState }
    VitalsState { id: vitalsState }

    property bool hoverShown: false   // tooltip mode: click-through, hides when the cursor leaves
    property bool pinned: false       // click mode: fullscreen closer, click anywhere / Esc dismisses
    property real iconX: 0            // widget centre in screen coords
    property bool suppressHover: false

    readonly property int colWidth: 280

    implicitWidth: icons.implicitWidth + 12
    implicitHeight: 22

    function captureX() { iconX = root.mapToItem(null, root.width / 2, 0).x }

    function dismiss() {
        pinned = false
        hoverShown = false
        // the fullscreen closer vanishes under the cursor; without this the
        // widget would instantly see "hover" again and reopen the tooltip
        suppressHover = true
        suppressTimer.restart()
    }

    Timer {
        id: suppressTimer
        interval: 400
        onTriggered: root.suppressHover = false
    }

    // same highlight as the active workspace and the notification badge
    Rectangle {
        anchors.fill: parent
        radius: 4
        visible: root.pinned || area.containsMouse
        color: Qt.rgba(theme.fg.r, theme.fg.g, theme.fg.b, root.pinned ? 0.12 : 0.06)
    }

    // ---- bar icons -------------------------------------------------------
    RowLayout {
        id: icons
        anchors.centerIn: parent
        spacing: 12

        RowLayout {
            spacing: 3
            NetworkIcon { net: netState }
            BluetoothIcon { bt: btState; visible: btState.enabled }
        }

        AudioIcons { audio: audioState }
        VitalsIcons { vitals: vitalsState }
    }

    MouseArea {
        id: area
        anchors.fill: parent
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

    // ---- tooltip + panel -------------------------------------------------
    // fully click-through while hovering (empty input region)
    Region { id: passThrough }

    PanelWindow {
        id: overlay
        visible: root.pinned || root.hoverShown

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "control-panel"
        WlrLayershell.keyboardFocus: root.pinned ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        exclusiveZone: 0

        anchors { top: true; right: true; bottom: true; left: true }
        color: "transparent"
        mask: root.pinned ? null : passThrough

        // Keys can't attach to a PanelWindow, so Esc goes through an inner Item
        Item {
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: root.dismiss()
        }

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
            width: Math.min(320, summary.implicitWidth + 24)
            height: summary.implicitHeight + 16
            radius: 4
            color: Qt.rgba(theme.bg.r, theme.bg.g, theme.bg.b, 0.92)

            Summary {
                id: summary
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                anchors.topMargin: 8
                anchors.bottomMargin: 8
                net: netState
                bt: btState
                audio: audioState
                vitals: vitalsState
            }
        }

        // click panel: two columns, scrolls if the screen is too short
        Rectangle {
            id: box
            visible: root.pinned
            y: 10
            x: Math.max(10, Math.min(overlay.width - width - 10, root.iconX - width / 2))
            width: root.colWidth * 2 + 16 + 24
            height: Math.min(overlay.height - 40, cols.implicitHeight + 24)
            radius: 4
            color: Qt.rgba(theme.bg.r, theme.bg.g, theme.bg.b, 0.92)
            clip: true

            // swallows clicks so they don't fall through to the fullscreen closer
            MouseArea { anchors.fill: parent; onClicked: {} }

            Flickable {
                anchors.fill: parent
                anchors.margins: 12
                contentWidth: width
                contentHeight: cols.implicitHeight
                interactive: contentHeight > height
                boundsBehavior: Flickable.StopAtBounds
                clip: true

                RowLayout {
                    id: cols
                    width: parent.width
                    spacing: 16

                    ColumnLayout {
                        Layout.preferredWidth: root.colWidth
                        Layout.alignment: Qt.AlignTop
                        spacing: 16

                        NetworkCard { Layout.fillWidth: true; net: netState }
                        BluetoothCard { Layout.fillWidth: true; bt: btState; visible: btState.enabled }
                    }

                    ColumnLayout {
                        Layout.preferredWidth: root.colWidth
                        Layout.alignment: Qt.AlignTop
                        spacing: 16

                        AudioCard { Layout.fillWidth: true; audio: audioState }
                        VitalsCard { Layout.fillWidth: true; vitals: vitalsState }
                    }
                }
            }
        }
    }
}
