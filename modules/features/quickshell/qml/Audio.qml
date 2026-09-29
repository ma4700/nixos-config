import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts

// Bar icon: speaker + mic pair
// On hover: volume readout
// On click: simple audio menu 
Item {
    id: root

    Theme { id: theme }

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property bool sinkMuted: root.sink && root.sink.audio ? root.sink.audio.muted : false
    readonly property real sinkVol: root.sink && root.sink.audio ? root.sink.audio.volume : 0
    readonly property bool sourceMuted: root.source && root.source.audio ? root.source.audio.muted : false
    readonly property real sourceVol: root.source && root.source.audio ? root.source.audio.volume : 0

    readonly property var sinks: Pipewire.nodes.values.filter(n => n.audio && n.isSink && !n.isStream)
    readonly property var sources: Pipewire.nodes.values.filter(n => n.audio && !n.isSink && !n.isStream)

    // binding every device to use their .audio properties
    PwObjectTracker {
        objects: [root.sink, root.source].concat(root.sinks, root.sources)
    }

    property bool hoverShown: false
    property bool pinned: false
    property real iconX: 0
    property bool suppressHover: false
    readonly property bool shown: pinned || hoverShown

    implicitWidth: 32
    implicitHeight: 12

    onSinkMutedChanged: spk.requestPaint()
    onSourceMutedChanged: mic.requestPaint()

    function pct(v) { return Math.round(v * 100) + "%" }
    function captureX() { iconX = root.mapToItem(null, root.width / 2, 0).x }

    function dismiss() {
        pinned = false
        hoverShown = false
        suppressHover = true
        suppressTimer.restart()
    }

    Timer {
        id: suppressTimer
        interval: 400
        onTriggered: root.suppressHover = false
    }

    // ---- icons -----------------------------------------------------------
    RowLayout {
        anchors.fill: parent
        spacing: 3

        Canvas {
            id: spk
            width: 14; height: 12
            onPaint: {
                const ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                ctx.fillStyle = theme.mid
                ctx.beginPath()
                ctx.moveTo(1, 4.5); ctx.lineTo(4, 4.5); ctx.lineTo(8, 1)
                ctx.lineTo(8, 11); ctx.lineTo(4, 7.5); ctx.lineTo(1, 7.5)
                ctx.closePath()
                ctx.fill()
                if (!root.sinkMuted) {
                    ctx.strokeStyle = theme.dim
                    ctx.lineWidth = 1.1
                    ctx.beginPath(); ctx.arc(8, 6, 3.4, -0.6, 0.6); ctx.stroke()
                    ctx.beginPath(); ctx.arc(8, 6, 5.6, -0.6, 0.6); ctx.stroke()
                } else {
                    ctx.strokeStyle = theme.red
                    ctx.lineWidth = 1.4
                    ctx.beginPath(); ctx.moveTo(1, 11); ctx.lineTo(12.5, 0.5); ctx.stroke()
                }
            }
        }

        Canvas {
            id: mic
            width: 14; height: 12
            onPaint: {
                const ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                ctx.fillStyle = theme.mid
                ctx.beginPath()
                ctx.moveTo(5, 1)
                ctx.arcTo(9, 1, 9, 5, 2); ctx.lineTo(9, 5)
                ctx.arcTo(9, 8, 5, 8, 2); ctx.lineTo(5, 8)
                ctx.arcTo(5, 5, 5, 1, 2)
                ctx.closePath()
                ctx.fill()
                ctx.strokeStyle = theme.mid
                ctx.lineWidth = 1.1
                ctx.beginPath(); ctx.arc(7, 6, 4, 0.3, Math.PI - 0.3); ctx.stroke()
                ctx.beginPath(); ctx.moveTo(7, 10); ctx.lineTo(7, 11.5); ctx.stroke()
                ctx.beginPath(); ctx.moveTo(4, 11.5); ctx.lineTo(10, 11.5); ctx.stroke()
                if (root.sourceMuted) {
                    ctx.strokeStyle = theme.red
                    ctx.lineWidth = 1.4
                    ctx.beginPath(); ctx.moveTo(1, 11); ctx.lineTo(12.5, 0.5); ctx.stroke()
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -6
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

    Region { id: passThrough }

    PanelWindow {
        id: overlay
        visible: root.shown

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "audio-info"
        WlrLayershell.keyboardFocus: root.pinned ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        exclusiveZone: 0

        anchors { top: true; right: true; bottom: true; left: true }
        color: "transparent"
        mask: root.pinned ? null : passThrough

        Keys.onEscapePressed: root.dismiss()

        MouseArea {
            anchors.fill: parent
            enabled: root.pinned
            onClicked: root.dismiss()
        }

        // hover tooltip: just the numbers
        Rectangle {
            visible: root.hoverShown && !root.pinned
            y: 10
            x: Math.max(10, Math.min(overlay.width - width - 10, root.iconX - width / 2))
            width: tipCol.implicitWidth + 24
            height: tipCol.implicitHeight + 16
            radius: 4
            color: Qt.rgba(theme.bg.r, theme.bg.g, theme.bg.b, 0.92)

            ColumnLayout {
                id: tipCol
                anchors.fill: parent
                anchors.margins: 8
                spacing: 2

                Text {
                    text: "Speakers  " + (root.sinkMuted ? "Muted" : root.pct(root.sinkVol))
                    color: theme.fg
                    font.family: "JetBrains Mono"
                    font.pixelSize: 12
                }
                Text {
                    text: "Mic  " + (root.sourceMuted ? "Muted" : root.pct(root.sourceVol))
                    color: theme.fg
                    font.family: "JetBrains Mono"
                    font.pixelSize: 12
                }
            }
        }

        // click menu: full controls
        Rectangle {
            id: box
            visible: root.pinned
            y: 10
            x: Math.max(10, Math.min(overlay.width - width - 10, root.iconX - width / 2))
            width: 260
            height: menuCol.implicitHeight + 24
            radius: 4
            color: Qt.rgba(theme.bg.r, theme.bg.g, theme.bg.b, 0.92)

            MouseArea { anchors.fill: parent; onClicked: {} }

            ColumnLayout {
                id: menuCol
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                Text {
                    text: "Audio"
                    color: theme.fg
                    font.family: "JetBrains Mono"
                    font.pixelSize: 14
                    font.bold: true
                }

                AudioSection {
                    Layout.fillWidth: true
                    label: "Output"
                    isOutput: true
                    devices: root.sinks
                    current: root.sink
                }

                AudioSection {
                    Layout.fillWidth: true
                    label: "Input"
                    isOutput: false
                    devices: root.sources
                    current: root.source
                }
            }
        }
    }
}
