import Quickshell
import Quickshell.Io
import QtQuick

// nmcli, polled every 5s. The detailed info is only fetched while
// detailsWanted is true, i.e. while the panel is open.
Scope {
    id: root

    property bool detailsWanted: false

    // "wifi" | "ethernet" | "none"
    property string kind: "none"
    property string dev: ""
    property string conn: ""
    property int sigPct: 0
    property var details: ({ dns: [] })

    readonly property int level: Math.min(3, Math.max(1, Math.ceil(sigPct / 33.4)))
    readonly property var rows: buildRows()

    onDevChanged: {
        details = ({ dns: [] })
        fetchDetails()
    }
    onDetailsWantedChanged: fetchDetails()

    function fetchDetails() {
        if (detailsWanted && kind !== "none" && !detailProc.running) detailProc.running = true
    }

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
}
