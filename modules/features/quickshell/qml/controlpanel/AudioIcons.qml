import QtQuick
import QtQuick.Layouts
import qs

// speaker + mic, red diagonal bar when muted
RowLayout {
    id: root

    required property var audio

    Theme { id: theme }

    readonly property bool sinkMuted: root.audio.sinkMuted
    readonly property bool sourceMuted: root.audio.sourceMuted

    spacing: 3

    onSinkMutedChanged: spk.requestPaint()
    onSourceMutedChanged: mic.requestPaint()

    Canvas {
        id: spk
        implicitWidth: 14; implicitHeight: 12
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
        implicitWidth: 14; implicitHeight: 12
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
