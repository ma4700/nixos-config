import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// Bar icon: wifi / ethernet / no network. Hover or click for details,
// same behaviour and styling as Battery.qml and NotificationCenter.qml.
Item {
    id: root

    Theme { id: theme }

    // "wifi" | "ethernet" | "none"
    property string kind: "none"
    property string dev: ""
    property string conn: ""
    property int sigPct: 0
    property var details: ({ dns: [] })

    readonly property int level: Math.min(3, Math.max(1, Math.ceil(sigPct / 33.4)))
    readonly property color litColor: theme.mid
    readonly property color dimColor: theme.dim

    property bool hoverShown: false   // tooltip mode: follows the cursor, click-through
    property bool pinned: false       // click mode: fullscreen closer, click anywhere / Esc dismisses
    property real iconX: 0
    property bool suppressHover: false

    readonly property bool shown: pinned || hoverShown

    implicitWidth: 16
    implicitHeight: 12

    onKindChanged: cv.requestPaint()
    onSigPctChanged: cv.requestPaint()
    onDevChanged: details = ({ dns: [] })
    onShownChanged: if (shown && kind !== "none" && !detailProc.running) detailProc.running = true

    function unesc(s) { return s.replace(/\\:/g, ":") }
    function dash(v) { return (v && v !== "--") ? v : "–" }

    // ---- polling -------------------------------------------------------
    // LC_ALL=C so nmcli prints "yes"/"connected" regardless of locale
    Process {
        id: poll
        command: ["sh", "-c",
            "export LC_ALL=C; " +
            "nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device status; " +
            "echo '--WIFI--'; " +
            "nmcli -t -f ACTIVE,SIGNAL device wifi list --rescan no 2>/dev/null"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.parsePoll(this.text)
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: if (!poll.running) poll.running = true
    }

    function parsePoll(text) {
        let eth = null, wifi = null, sig = 0, inWifi = false
        for (const line of text.split("\n")) {
            if (line === "--WIFI--") { inWifi = true; continue }
            if (!line) continue
            if (!inWifi) {
                const p = line.split(":")
                if (p.length < 3 || !p[2].startsWith("connected")) continue
                const c = unesc(p.slice(3).join(":"))
                if (p[1] === "ethernet" && !eth) eth = { dev: p[0], conn: c }
                else if (p[1] === "wifi" && !wifi) wifi = { dev: p[0], conn: c }
            } else if (line.startsWith("yes:")) {
                sig = parseInt(line.split(":")[1]) || 0
            }
        }
        const a = eth ? eth : wifi
        kind = eth ? "ethernet" : wifi ? "wifi" : "none"
        dev = a ? a.dev : ""
        conn = a ? a.conn : ""
        sigPct = sig
    }

    // ---- details (only fetched while the panel is open) ----------------
    Process {
        id: detailProc
        command: ["sh", "-c",
            "export LC_ALL=C; " +
            "nmcli -t -f GENERAL.HWADDR,IP4.ADDRESS,IP4.GATEWAY,IP4.DNS device show \"$1\"; " +
            "echo '--WIFI--'; " +
            "nmcli -t -f ACTIVE,SIGNAL,RATE,CHAN,FREQ,SECURITY,SSID device wifi list ifname \"$1\" --rescan no 2>/dev/null",
            "sh", root.dev]
        stdout: StdioCollector {
            onStreamFinished: root.parseDetails(this.text)
        }
    }

    function parseDetails(text) {
        const info = { dns: [] }
        let inWifi = false
        for (const line of text.split("\n")) {
            if (line === "--WIFI--") { inWifi = true; continue }
            if (!line) continue
            if (!inWifi) {
                const i = line.indexOf(":")
                if (i < 0) continue
                const key = line.slice(0, i), val = unesc(line.slice(i + 1))
                if (key.startsWith("IP4.ADDRESS")) info.ip = info.ip || val
                else if (key === "IP4.GATEWAY") info.gw = val
                else if (key.startsWith("IP4.DNS")) info.dns.push(val)
                else if (key === "GENERAL.HWADDR") info.mac = val
            } else if (line.startsWith("yes:")) {
                const f = line.split(":")
                info.rate = f[2]
                info.chan = f[3]
                info.freq = f[4]
                info.security = f[5]
            }
        }
        details = info
    }

    function buildRows() {
        const d = details
        const dns = d.dns.length > 0 ? d.dns.join(", ") : ""
        if (kind === "wifi") {
            return [
                ["Network", dash(conn)],
                ["Signal", sigPct + "%"],
                ["Security", d.security === "--" ? "Open" : dash(d.security)],
                ["Channel", d.chan ? d.chan + " (" + d.freq + ")" : "–"],
                ["Rate", dash(d.rate)],
                ["IP", dash(d.ip)],
                ["Gateway", dash(d.gw)],
                ["DNS", dash(dns)]
            ]
        }
        if (kind === "ethernet") {
            return [
                ["Connection", dash(conn)],
                ["Device", dash(dev)],
                ["IP", dash(d.ip)],
                ["Gateway", dash(d.gw)],
                ["DNS", dash(dns)],
                ["MAC", dash(d.mac)]
            ]
        }
        return []
    }
    readonly property var rows: buildRows()

    function captureX() {
        iconX = root.mapToItem(null, root.width / 2, 0).x
    }

    function dismiss() {
        pinned = false
        hoverShown = false
        // the fullscreen closer vanishes under the cursor; without this the
        // icon would instantly see "hover" again and reopen the tooltip
        suppressHover = true
        suppressTimer.restart()
    }

    Timer {
        id: suppressTimer
        interval: 400
        onTriggered: root.suppressHover = false
    }

    // ---- icon ----------------------------------------------------------
    Canvas {
        id: cv
        width: 14; height: 11
        anchors.centerIn: parent

        onPaint: {
            const ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            ctx.lineCap = "round"
            ctx.lineWidth = 1.3

            function arcs(litCount, lit, dim) {
                const radii = [3.5, 6.2, 8.9]
                for (let i = 0; i < 3; i++) {
                    ctx.strokeStyle = (i < litCount) ? lit : dim
                    ctx.beginPath()
                    ctx.arc(7, 10, radii[i], -3 * Math.PI / 4, -Math.PI / 4)
                    ctx.stroke()
                }
            }
            function dot(color) {
                ctx.fillStyle = color
                ctx.beginPath()
                ctx.arc(7, 9.5, 1.1, 0, 2 * Math.PI)
                ctx.fill()
            }

            if (root.kind === "wifi") {
                arcs(root.level, root.litColor, root.dimColor)
                dot(root.litColor)
            } else if (root.kind === "ethernet") {
                ctx.strokeStyle = root.litColor
                ctx.lineWidth = 1.2
                ctx.strokeRect(2.5, 1.5, 9, 6.5)          // plug body
                ctx.beginPath()                            // latch
                ctx.moveTo(5, 8); ctx.lineTo(5, 10)
                ctx.lineTo(9, 10); ctx.lineTo(9, 8)
                ctx.stroke()
                ctx.beginPath()                            // pins
                for (const x of [5, 7, 9]) { ctx.moveTo(x, 1.5); ctx.lineTo(x, 4.5) }
                ctx.stroke()
            } else {
                arcs(0, root.litColor, root.dimColor)
                dot(root.dimColor)
                ctx.strokeStyle = theme.red                // slash
                ctx.lineWidth = 1.4
                ctx.beginPath()
                ctx.moveTo(1.5, 1); ctx.lineTo(12.5, 10.5)
                ctx.stroke()
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -6    // larger hit area than the tiny icon
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

    // fully click-through while hovering (empty input region)
    Region { id: passThrough }

    // Same structure as Battery / NotificationCenter: fullscreen window + inner box
    PanelWindow {
        id: overlay
        visible: root.shown

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "network-info"
        WlrLayershell.keyboardFocus: root.pinned ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        exclusiveZone: 0

        anchors {
            top: true
            right: true
            bottom: true
            left: true
        }

        color: "transparent"

        // hover: input passes through so the tooltip goes away when the cursor
        // leaves the icon; pinned: full input so a click anywhere dismisses it
        mask: root.pinned ? null : passThrough

        Keys.onEscapePressed: root.dismiss()

        MouseArea {
            anchors.fill: parent
            enabled: root.pinned
            onClicked: root.dismiss()
        }

        Rectangle {
            id: box
            y: 10
            x: Math.max(10, Math.min(overlay.width - width - 10, root.iconX - width / 2))

            width: 260
            height: contentCol.implicitHeight + 24
            radius: 4
            color: Qt.rgba(theme.bg.r, theme.bg.g, theme.bg.b, 0.92)

            // swallows clicks so they don't fall through to the fullscreen closer
            MouseArea {
                anchors.fill: parent
                onClicked: {}
            }

            ColumnLayout {
                id: contentCol
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                Text {
                    text: "Network"
                    color: theme.fg
                    font.family: "JetBrains Mono"
                    font.pixelSize: 14
                    font.bold: true
                    Layout.fillWidth: true
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: info.implicitHeight + 16
                    radius: 4
                    color: Qt.rgba(theme.fg.r, theme.fg.g, theme.fg.b, 0.06)

                    ColumnLayout {
                        id: info
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 4

                        Text {
                            text: root.kind === "wifi" ? "Wi-Fi"
                                : root.kind === "ethernet" ? "Ethernet"
                                : "Not connected"
                            color: root.kind === "none" ? theme.red : theme.fg
                            font.family: "JetBrains Mono"
                            font.pixelSize: 13
                            font.bold: true
                        }

                        Text {
                            visible: root.kind === "none"
                            text: "No active connection"
                            color: theme.mid
                            font.family: "JetBrains Mono"
                            font.pixelSize: 12
                        }

                        Repeater {
                            model: root.rows

                            RowLayout {
                                id: row
                                required property var modelData
                                Layout.fillWidth: true
                                spacing: 10

                                Text {
                                    text: row.modelData[0]
                                    color: theme.mid
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 12
                                    Layout.preferredWidth: 78
                                    Layout.alignment: Qt.AlignTop
                                }

                                Text {
                                    text: row.modelData[1]
                                    color: theme.fg
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 12
                                    wrapMode: Text.WrapAnywhere
                                    Layout.fillWidth: true
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
