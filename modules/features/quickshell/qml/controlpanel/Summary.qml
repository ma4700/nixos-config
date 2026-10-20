import QtQuick
import QtQuick.Layouts
import qs

// Hover tooltip: one line per section of the panel
InfoRows {
    id: root

    required property var net
    required property var bt
    required property var audio
    required property var vitals

    Theme { id: colors }

    wrap: false
    spacing: 2

    function netLine() {
        if (root.net.kind === "wifi") return ["Wi-Fi", root.net.conn + "  " + root.net.sigPct + "%"]
        if (root.net.kind === "ethernet") return ["Ethernet", root.net.conn]
        return ["Network", "Not connected", colors.red]
    }

    function btLine() {
        if (!root.bt.powered) return ["Bluetooth", "Off", colors.dim]
        if (root.bt.connectedDevices.length > 0)
            return ["Bluetooth", root.bt.connectedDevices.map(d => d.name).join(", ")]
        return ["Bluetooth", "Not connected"]
    }

    rows: {
        const a = root.audio, v = root.vitals
        const r = [netLine()]
        if (root.bt.enabled) r.push(btLine())
        r.push(["Speakers", a.sinkMuted ? "Muted" : a.pct(a.sinkVol)])
        r.push(["Mic", a.sourceMuted ? "Muted" : a.pct(a.sourceVol)])
        r.push(["CPU", Math.round(v.cpuPct) + "%", v.cpuColor])
        r.push(["Memory", v.memPct + "%", v.memColor])
        return r
    }
}
