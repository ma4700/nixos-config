import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts

// Runs qs-bt-agent (the BlueZ pairing agent) for as long as the shell runs
// and shows its requests as a small prompt under the bar.
// While the screen is locked every request is refused.
Scope {
    id: root

    property bool locked: false

    Theme { id: theme }

    // prompts waiting for an answer, the first one is on screen
    property var queue: []
    readonly property var req: queue.length > 0 ? queue[0] : null
    readonly property string reqKey: req ? req.kind + req.id + req.path : ""
    readonly property var device: req ? Bluetooth.devices.values.find(d => d.dbusPath === req.path) ?? null : null
    readonly property string deviceName: device ? device.name : (req ? macFromPath(req.path) : "")
    readonly property bool needsInput: req !== null && (req.kind === "pin" || req.kind === "passkey")

    // a "type this code" prompt closes by itself once the device is paired
    readonly property bool showDone: req !== null && req.kind === "show" && device !== null && device.paired
    onShowDoneChanged: if (showDone) close()

    onReqKeyChanged: input.text = ""

    onLockedChanged: {
        if (locked) {
            for (const r of queue)
                if (r.id !== "") send("no " + r.id)
            queue = []
        } else {
            // another user's session may have taken over while this one was locked
            send("default")
        }
    }

    readonly property string title: {
        if (!req) return ""
        switch (req.kind) {
        case "confirm":   return "Pair with " + deviceName + "?"
        case "authorize": return deviceName + " wants to pair"
        case "service":   return deviceName + " wants to connect"
        case "pin":       return "PIN for " + deviceName
        case "passkey":   return "Passkey for " + deviceName
        default:          return "Type this on " + deviceName
        }
    }

    readonly property string detail: {
        if (!req) return ""
        switch (req.kind) {
        case "confirm":   return "Check that the device shows the same code"
        case "authorize": return "Only allow this if you started pairing on the device"
        case "service":   return "for " + serviceName(req.uuid)
        case "pin":       return "Enter the device's PIN"
        case "passkey":   return "Enter the code shown on the device"
        default:          return "then press Enter on the device"
        }
    }

    readonly property string acceptLabel: req && (req.kind === "authorize" || req.kind === "service") ? "allow" : "pair"
    readonly property string denyLabel: !req ? "" : req.kind === "show" ? "close"
        : (req.kind === "authorize" || req.kind === "service") ? "deny" : "cancel"

    function macFromPath(p) {
        const m = p.match(/dev_([0-9A-Fa-f_]+)$/)
        return m ? m[1].replace(/_/g, ":") : p
    }

    function serviceName(uuid) {
        const names = {
            "110a": "audio input", "110b": "audio", "110c": "media controls", "110e": "media controls",
            "1108": "headset", "1112": "headset", "111e": "hands-free", "111f": "hands-free",
            "1124": "keyboard/mouse", "1105": "file transfer", "1106": "file transfer",
            "112f": "contacts", "1132": "messages", "1115": "network", "1116": "network"
        }
        return names[uuid.slice(4, 8).toLowerCase()] ?? uuid
    }

    function send(line) {
        if (agent.running)
            agent.write(line + "\n")
    }

    function push(r) {
        if (root.locked) {
            if (r.id !== "") send("no " + r.id)
            return
        }
        // a new "type this code" prompt for the same device replaces the old one
        if (r.kind === "show")
            queue = queue.filter(q => !(q.kind === "show" && q.path === r.path))
        queue = queue.concat([r])
    }

    function drop(id) {
        queue = queue.filter(q => q.id !== id)
    }

    function close() {
        queue = queue.slice(1)
    }

    function accept() {
        const r = req
        if (!r) return
        if (r.kind === "pin") {
            if (!/^[!-~]{1,16}$/.test(input.text)) return
            send("pin " + r.id + " " + input.text)
        } else if (r.kind === "passkey") {
            if (!/^[0-9]{1,6}$/.test(input.text)) return
            send("passkey " + r.id + " " + input.text)
        } else if (r.kind !== "show") {
            send("yes " + r.id)
        }
        close()
    }

    function deny() {
        if (req && req.id !== "") send("no " + req.id)
        close()
    }

    function handle(line) {
        const f = line.split(" ")
        switch (f[0]) {
        case "confirm":      push({ kind: "confirm", id: f[1], path: f[2], code: f[3] }); break
        case "authorize":    push({ kind: "authorize", id: f[1], path: f[2] }); break
        case "service":      push({ kind: "service", id: f[1], path: f[2], uuid: f[3] }); break
        case "pin":          push({ kind: "pin", id: f[1], path: f[2] }); break
        case "passkey":      push({ kind: "passkey", id: f[1], path: f[2] }); break
        case "show-pin":
        case "show-passkey": push({ kind: "show", id: "", path: f[1], code: f[2] }); break
        case "cancel":       drop(f[1]); break
        case "error":        console.warn("qs-bt-agent:", line); break
        }
    }

    Process {
        id: agent
        command: [BluetoothFeature.agent]
        running: BluetoothFeature.enabled
        stdinEnabled: true
        stdout: SplitParser {
            onRead: data => root.handle(data)
        }
        onExited: {
            root.queue = []
            if (BluetoothFeature.enabled) restart.start()
        }
    }

    // bring the agent back if it ever dies
    Timer {
        id: restart
        interval: 3000
        onTriggered: agent.running = true
    }

    PanelWindow {
        id: prompt
        visible: root.req !== null

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "bluetooth-prompt"
        // keyboard only after clicking the prompt, so a prompt that pops up
        // can't swallow keys you're typing somewhere else
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        exclusiveZone: 0

        anchors.top: true
        margins.top: 10
        implicitWidth: 300
        implicitHeight: col.implicitHeight + 24
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: 4
            color: Qt.rgba(theme.bg.r, theme.bg.g, theme.bg.b, 0.92)
            focus: true
            Keys.onEscapePressed: root.deny()

            ColumnLayout {
                id: col
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: root.title
                    elide: Text.ElideRight
                    color: theme.fg
                    font.family: "JetBrains Mono"
                    font.pixelSize: 13
                    font.bold: true
                }

                Text {
                    visible: root.req !== null && (root.req.kind === "confirm" || root.req.kind === "show")
                    text: root.req && root.req.code ? root.req.code : ""
                    color: theme.bright
                    font.family: "JetBrains Mono"
                    font.pixelSize: 20
                    font.letterSpacing: 2
                }

                Text {
                    Layout.fillWidth: true
                    text: root.detail
                    wrapMode: Text.WordWrap
                    color: theme.mid
                    font.family: "JetBrains Mono"
                    font.pixelSize: 12
                }

                Rectangle {
                    visible: root.needsInput
                    Layout.fillWidth: true
                    implicitHeight: 26
                    radius: 4
                    color: Qt.rgba(theme.fg.r, theme.fg.g, theme.fg.b, 0.08)

                    TextInput {
                        id: input
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        verticalAlignment: TextInput.AlignVCenter
                        clip: true
                        color: theme.bright
                        font.family: "JetBrains Mono"
                        font.pixelSize: 13
                        maximumLength: root.req && root.req.kind === "passkey" ? 6 : 16
                        Keys.onReturnPressed: root.accept()
                        Keys.onEnterPressed: root.accept()
                        Keys.onEscapePressed: root.deny()
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.IBeamCursor
                        onClicked: input.forceActiveFocus()
                    }
                }

                RowLayout {
                    Layout.alignment: Qt.AlignRight
                    spacing: 16

                    Text {
                        text: root.denyLabel
                        color: root.req && root.req.kind === "show" ? theme.mid : theme.red
                        font.family: "JetBrains Mono"
                        font.pixelSize: 12

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.deny()
                        }
                    }

                    Text {
                        visible: root.req !== null && root.req.kind !== "show"
                        text: root.acceptLabel
                        color: theme.green
                        font.family: "JetBrains Mono"
                        font.pixelSize: 12

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.accept()
                        }
                    }
                }
            }
        }
    }
}
