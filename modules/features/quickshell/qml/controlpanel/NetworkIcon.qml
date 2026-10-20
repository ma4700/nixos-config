import QtQuick
import qs

// wifi arcs by signal / ethernet plug / red slash when offline
Item {
    id: root

    required property var net

    Theme { id: theme }

    readonly property string kind: root.net.kind
    readonly property int level: root.net.level
    readonly property color litColor: theme.mid
    readonly property color dimColor: theme.dim

    implicitWidth: 16
    implicitHeight: 12

    onKindChanged: cv.requestPaint()
    onLevelChanged: cv.requestPaint()

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
}
