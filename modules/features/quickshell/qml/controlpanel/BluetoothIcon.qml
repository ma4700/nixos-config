import QtQuick
import qs

// Bluetooth rune, dim while the adapter is off
Item {
    id: root

    required property var bt

    Theme { id: theme }

    readonly property bool powered: root.bt.powered

    implicitWidth: 14
    implicitHeight: 12

    onPoweredChanged: cv.requestPaint()

    Canvas {
        id: cv
        anchors.fill: parent
        onPaint: {
            const ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            ctx.strokeStyle = root.powered ? theme.mid : theme.dim
            ctx.lineWidth = 1.3
            ctx.lineCap = "round"
            ctx.lineJoin = "round"
            ctx.beginPath()
            ctx.moveTo(7, 1)
            ctx.lineTo(11, 4)
            ctx.lineTo(7, 6)
            ctx.lineTo(11, 8)
            ctx.lineTo(7, 11)
            ctx.lineTo(7, 1)
            ctx.stroke()
        }
    }
}
