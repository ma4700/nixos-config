import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// Power / session menu: lock, logout, suspend, reboot, shutdown.
PanelWindow {
    id: panel
    signal closeRequested()
    signal lockRequested()

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "session-menu"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusiveZone: 0

    anchors {
        top: true
        right: true
        bottom: true
        left: true
    }

    color: Qt.rgba(theme.bg.r, theme.bg.g, theme.bg.b, 0.45)

    Theme { id: theme }

    readonly property var actions: [
        { label: "Lock",     key: "l", danger: false, lock: true, cmd: [] },
        { label: "Logout",   key: "o", danger: false, cmd: ["hyprctl", "dispatch", "exit"] },
        { label: "Suspend",  key: "s", danger: false, cmd: ["systemctl", "suspend"] },
        { label: "Reboot",   key: "r", danger: true,  verb: "reboot",    cmd: ["systemctl", "reboot"] },
        { label: "Shutdown", key: "p", danger: true,  verb: "shut down", cmd: ["systemctl", "poweroff"] }
    ]

    property int current: 0
    property int armed: -1
    property string otherUser: ""
    property bool confirming: false
    property var pending: null

    Process {
        id: sessions
        command: ["loginctl", "list-sessions", "--json=short"]
        stdout: StdioCollector {
            onStreamFinished: {
                let other = "";
                try {
                    const s = JSON.parse(text).find(x => x.class === "user" && x.user !== Quickshell.env("USER"));
                    if (s) other = s.user;
                } catch (e) {}
                panel.otherUser = other;
            }
        }
    }

    function run(action) {
        if (action.danger && panel.otherUser !== "") {
            panel.pending = action;
            panel.confirming = true;
            return;
        }
        panel.closeRequested();
        if (action.lock) panel.lockRequested();
        else Quickshell.execDetached(action.cmd);
    }

    onVisibleChanged: {
        if (visible) {
            current = 0;
            armed = -1;
            confirming = false;
            sessions.running = true;
            keys.forceActiveFocus();
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: panel.closeRequested()
    }

    Item {
        id: keys
        focus: true

        Keys.onPressed: event => {
            const ctrl = event.modifiers & Qt.ControlModifier;
            const last = panel.actions.length - 1;

            if (panel.confirming) {
                if (event.key === Qt.Key_Escape) {
                    panel.confirming = false;
                    panel.closeRequested();
                } else if (event.key === Qt.Key_Y) {
                    panel.confirming = false;
                    panel.closeRequested();
                    Quickshell.execDetached(panel.pending.cmd);
                } else if (event.key === Qt.Key_N) {
                    panel.confirming = false;
                }
            } else if (event.key === Qt.Key_Escape) {
                panel.closeRequested();
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                panel.run(panel.actions[panel.current]);
            } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J
                       || (ctrl && event.key === Qt.Key_N)) {
                panel.current = Math.min(panel.current + 1, last);
                panel.armed = -1;
            } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K
                       || (ctrl && event.key === Qt.Key_P)) {
                panel.current = Math.max(panel.current - 1, 0);
                panel.armed = -1;
            } else {
                const idx = panel.actions.findIndex(a => a.key === event.text.toLowerCase());
                if (idx < 0 || ctrl) return;
                if (panel.armed === idx || (panel.actions[idx].danger && panel.otherUser !== "")) {
                    panel.run(panel.actions[idx]);
                } else {
                    panel.current = idx;
                    panel.armed = idx;
                }
            }
            event.accepted = true;
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width: 240
        height: list.implicitHeight + 24
        radius: 4
        visible: !panel.confirming
        color: Qt.rgba(theme.bg.r, theme.bg.g, theme.bg.b, 0.92)

        // swallows clicks so they don't fall through to the fullscreen closer
        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        ColumnLayout {
            id: list
            anchors.fill: parent
            anchors.margins: 12
            spacing: 2

            Repeater {
                model: panel.actions

                Rectangle {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool selected: panel.current === row.index
                    readonly property bool armed: panel.armed === row.index

                    Layout.fillWidth: true
                    implicitHeight: 32
                    radius: 4
                    color: selected ? Qt.rgba(theme.fg.r, theme.fg.g, theme.fg.b, 0.12) : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10

                        Text {
                            text: row.modelData.label
                            color: !row.selected ? theme.mid
                                 : row.modelData.danger ? theme.red : theme.bright
                            font.family: "JetBrains Mono"
                            font.pixelSize: 13
                            Layout.fillWidth: true
                        }

                        Text {
                            text: row.armed ? "press " + row.modelData.key + " again" : row.modelData.key
                            color: row.armed ? (row.modelData.danger ? theme.red : theme.bright) : theme.dim
                            font.family: "JetBrains Mono"
                            font.pixelSize: 12
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: {
                            panel.current = row.index;
                            panel.armed = -1;
                        }
                        onClicked: panel.run(row.modelData)
                    }
                }
            }
        }
    }

    Rectangle {
        visible: panel.confirming
        anchors.centerIn: parent
        width: 320
        height: confirmCol.implicitHeight + 24
        radius: 4
        color: Qt.rgba(theme.bg.r, theme.bg.g, theme.bg.b, 0.92)

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        ColumnLayout {
            id: confirmCol
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12

            Text {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: panel.otherUser + "'s session is running. Still " + (panel.pending ? panel.pending.verb : "") + "?"
                color: theme.bright
                font.family: "JetBrains Mono"
                font.pixelSize: 13
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 24

                Text {
                    text: "y  yes"
                    color: theme.green
                    font.family: "JetBrains Mono"
                    font.pixelSize: 13
                }

                Text {
                    text: "n  no"
                    color: theme.red
                    font.family: "JetBrains Mono"
                    font.pixelSize: 13
                }
            }
        }
    }
}
