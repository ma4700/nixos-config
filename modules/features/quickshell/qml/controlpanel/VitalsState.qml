import Quickshell
import Quickshell.Io
import QtQuick
import qs

// CPU and RAM from /proc, polled every 2s
Scope {
    id: root

    Theme { id: theme }

    property real cpuPct: 0
    property int cores: 0
    property string loadAvg: ""
    property real memTotal: 0     // kB
    property real memAvail: 0
    property real swapTotal: 0
    property real swapFree: 0
    property real prevTotal: 0
    property real prevIdle: 0

    readonly property real memUsed: memTotal - memAvail
    readonly property real memPct: memTotal > 0 ? Math.round(100 * memUsed / memTotal) : 0

    // icon / percentage colour: yellow at 75%, red at 90%
    function levelColor(p) {
        return p >= 90 ? theme.red : p >= 75 ? theme.yellow : theme.mid
    }
    readonly property color cpuColor: levelColor(cpuPct)
    readonly property color memColor: levelColor(memPct)

    function gib(kb) { return (kb / 1048576).toFixed(1) + " GiB" }

    function buildRamRows() {
        const r = [
            ["Used", gib(memUsed)],
            ["Available", gib(memAvail)],
            ["Total", gib(memTotal)]
        ]
        if (swapTotal > 0) r.push(["Swap", gib(swapTotal - swapFree) + " / " + gib(swapTotal)])
        return r
    }

    readonly property var cpuRows: [
        ["Cores", cores > 0 ? String(cores) : "–"],
        ["Load", loadAvg !== "" ? loadAvg : "–"]
    ]
    readonly property var ramRows: buildRamRows()

    Process {
        id: poll
        command: ["sh", "-c",
            "head -n1 /proc/stat; cat /proc/loadavg; " +
            "grep -E '^(MemTotal|MemAvailable|SwapTotal|SwapFree):' /proc/meminfo; nproc"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.parse(this.text)
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: if (!poll.running) poll.running = true
    }

    function parse(text) {
        for (const line of text.split("\n")) {
            if (line.startsWith("cpu ")) {
                const f = line.trim().split(/\s+/).slice(1).map(Number)
                const idle = f[3] + (f[4] || 0)             // idle + iowait
                let total = 0
                for (let i = 0; i < 8 && i < f.length; i++) total += f[i]
                if (prevTotal > 0 && total > prevTotal)
                    cpuPct = Math.round(100 * ((total - prevTotal) - (idle - prevIdle)) / (total - prevTotal))
                prevTotal = total
                prevIdle = idle
            } else if (/^[0-9.]+ [0-9.]+ [0-9.]+ /.test(line)) {
                loadAvg = line.split(" ").slice(0, 3).join(" ")
            } else if (line.startsWith("MemTotal:")) {
                memTotal = parseInt(line.split(/\s+/)[1])
            } else if (line.startsWith("MemAvailable:")) {
                memAvail = parseInt(line.split(/\s+/)[1])
            } else if (line.startsWith("SwapTotal:")) {
                swapTotal = parseInt(line.split(/\s+/)[1])
            } else if (line.startsWith("SwapFree:")) {
                swapFree = parseInt(line.split(/\s+/)[1])
            } else if (/^[0-9]+$/.test(line)) {
                cores = parseInt(line)
            }
        }
    }
}
