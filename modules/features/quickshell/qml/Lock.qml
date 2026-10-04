import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import QtQuick
import QtQuick.Effects

// Minimal session lock: blurred wallpaper, clock, date, password dots.
// Lock with: quickshell ipc call lock lock
Scope {
    id: root

    // typed password lives here so every monitor shows the same dots
    property string buffer: ""
    property string status: ""
    property bool statusIsError: false
    readonly property bool locked: sessionLock.locked

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    function lockNow() {
        // no-op if already locked, so a second call can't wipe a half-typed password
        if (sessionLock.locked) return;
        root.buffer = "";
        root.status = "";
        sessionLock.locked = true;
    }

    IpcHandler {
        target: "lock"
        function lock(): void {
            root.lockNow();
        }
    }

    Timer {
        id: statusTimer
        interval: 2500
        onTriggered: root.status = ""
    }

    Process {
        id: sessionsProc
        command: ["loginctl", "list-sessions", "--json=short"]
        stdout: StdioCollector {
            onStreamFinished: root.switchTo(text)
        }
    }

    function switchUser() {
        sessionsProc.running = true;
    }

    function switchTo(json) {
        let sessions = [];
        try {
            sessions = JSON.parse(json);
        } catch (e) {
            return;
        }
        const vt = s => parseInt((s.tty || "").replace("tty", ""));
        const other = sessions.find(s => s.class === "user" && s.user !== Quickshell.env("USER") && vt(s) > 0);
        let target = other ? vt(other) : 0;
        if (!target) {
            const used = sessions.map(vt);
            target = 1;
            while (used.indexOf(target) >= 0) target++;
        }
        if (target > 6) return;
        Quickshell.execDetached(["busctl", "call", "org.freedesktop.login1",
            "/org/freedesktop/login1/seat/seat0", "org.freedesktop.login1.Seat",
            "SwitchTo", "u", String(target)]);
    }

    function submit() {
        if (pam.active || root.buffer.length === 0) return;
        root.status = "";
        pam.start();
    }

    PamContext {
        id: pam
        // /etc/pam.d/quickshell-lock, declared in the hyprland nixos module
        config: "quickshell-lock"

        onPamMessage: {
            if (responseRequired) {
                respond(root.buffer);
                root.buffer = "";
            }
        }

        onCompleted: result => {
            if (result === PamResult.Success) {
                root.buffer = "";
                root.status = "";
                sessionLock.locked = false;
            } else {
                root.buffer = "";
                root.statusIsError = true;
                root.status = result === PamResult.MaxTries ? "Too many attempts" : "Wrong password";
                statusTimer.restart();
            }
        }
    }

    WlSessionLock {
        id: sessionLock

        WlSessionLockSurface {
            id: surface
            color: "black"

            Theme { id: theme }
            WallpaperPath { id: wp }

            Image {
                id: img
                anchors.fill: parent
                source: wp.path
                fillMode: Image.PreserveAspectCrop
                visible: false
            }

            MultiEffect {
                anchors.fill: parent
                source: img
                blurEnabled: true
                blurMax: 48
                blur: 1.0
            }

            // dim so the text stays readable on any wallpaper
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(theme.bg.r, theme.bg.g, theme.bg.b, 0.72)
            }

            Item {
                anchors.fill: parent

                // Invisible input that owns keyboard focus; root.buffer mirrors it so
                // every monitor shows the same dots. Never logged, never displayed.
                TextInput {
                    id: keys
                    width: 1
                    height: 1
                    opacity: 0
                    focus: true
                    echoMode: TextInput.Password
                    inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
                    readOnly: pam.active

                    onTextChanged: {
                        if (text !== root.buffer) {
                            root.buffer = text;
                            if (text.length > 0) root.status = "";
                        }
                    }
                    onAccepted: root.submit()
                    Keys.onEscapePressed: root.buffer = ""

                    Connections {
                        target: root
                        function onBufferChanged() {
                            if (keys.text !== root.buffer) keys.text = root.buffer;
                        }
                    }

                    Component.onCompleted: forceActiveFocus()
                }

                // clicking anywhere re-grabs focus
                MouseArea {
                    anchors.fill: parent
                    onClicked: keys.forceActiveFocus()
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 24
                    width: 40
                    height: 40
                    radius: 4
                    color: Qt.rgba(theme.fg.r, theme.fg.g, theme.fg.b, switchArea.containsMouse ? 0.12 : 0.06)

                    Text {
                        anchors.centerIn: parent
                        text: "\uDB80\uDC19"
                        color: switchArea.containsMouse ? theme.bright : theme.mid
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 20
                    }

                    MouseArea {
                        id: switchArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.switchUser();
                            keys.forceActiveFocus();
                        }
                    }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatDateTime(clock.date, "HH:mm")
                        color: theme.bright
                        font.family: "JetBrains Mono"
                        font.pixelSize: 96
                        font.bold: true
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
                        color: theme.mid
                        font.family: "JetBrains Mono"
                        font.pixelSize: 16
                    }

                    Item { width: 1; height: 28 }

                    // password field
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 280
                        height: 40
                        radius: 4
                        color: Qt.rgba(theme.fg.r, theme.fg.g, theme.fg.b, 0.06)
                        border.width: 1
                        border.color: root.statusIsError && root.status !== ""
                                      ? theme.red
                                      : Qt.rgba(theme.fg.r, theme.fg.g, theme.fg.b, 0.12)

                        Text {
                            anchors.centerIn: parent
                            visible: root.buffer.length === 0
                            text: pam.active ? "checking..." : Quickshell.env("USER")
                            color: theme.dim
                            font.family: "JetBrains Mono"
                            font.pixelSize: 14
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: root.buffer.length > 0
                            text: "•".repeat(Math.min(root.buffer.length, 16))
                            color: theme.bright
                            font.family: "JetBrains Mono"
                            font.pixelSize: 18
                            font.letterSpacing: 4
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        height: 18
                        text: root.status
                        color: theme.red
                        font.family: "JetBrains Mono"
                        font.pixelSize: 12
                    }
                }
            }
        }
    }
}
