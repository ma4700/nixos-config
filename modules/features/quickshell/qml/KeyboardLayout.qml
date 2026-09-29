import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

// Event-driven: Hyprland pushes an "activelayout" event on every switch,
// so there is no polling.
Text {
    id: root

    Theme { id: theme }

    property string layoutName: ""   // e.g. "English (US)", "Greek"
    property string kbName: ""       // the main keyboard, so other devices are ignored

    // names that don't reduce nicely to a two-letter code
    readonly property var overrides: ({
        "Greek": "GR", "German": "DE", "French": "FR", "Spanish": "ES",
        "Russian": "RU", "Italian": "IT", "Portuguese": "PT", "Japanese": "JP",
        "Swedish": "SE", "Danish": "DK", "Polish": "PL", "Czech": "CZ"
    })

    function short(name) {
        // "English (US)" -> "US"; skip long variants like "(polytonic)"
        const m = name.match(/\(([^)]+)\)/)
        if (m && m[1].length <= 3) return m[1].toUpperCase()
        const base = name.replace(/\s*\(.*\)\s*/, "")
        if (overrides[base]) return overrides[base]
        return base.slice(0, 2).toUpperCase()
    }

    text: layoutName !== "" ? short(layoutName) : ""
    visible: text !== ""
    color: theme.mid
    font.family: "JetBrains Mono"
    font.pixelSize: 13

    // click: next layout
    MouseArea {
        anchors.fill: parent
        anchors.margins: -4
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["hyprctl", "switchxkblayout", "all", "next"])
    }

    // initial value
    Process {
        running: true
        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const kbs = JSON.parse(this.text).keyboards
                    const kb = kbs.find(k => k.main) || kbs[0]
                    if (kb) {
                        root.kbName = kb.name
                        root.layoutName = kb.active_keymap
                    }
                } catch (e) {}
            }
        }
    }

    // live updates: "activelayout>>keyboard-name,Layout Name"
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name !== "activelayout") return
            const i = event.data.indexOf(",")
            if (i < 0) return
            const kb = event.data.slice(0, i)
            if (root.kbName !== "" && kb !== root.kbName) return
            root.layoutName = event.data.slice(i + 1)
        }
    }
}
