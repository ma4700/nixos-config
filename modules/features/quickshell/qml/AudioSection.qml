import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire

// Audio section (output or input), volume slider / mute button
ColumnLayout {
    id: root
    spacing: 6

    property string label: ""
    property bool isOutput: true   // true: Output (sink), false: Input (source)
    property var devices: []       // [PwNode]
    property var current: null     // the default PwNode for this section, or null

    Theme { id: theme }

    readonly property bool muted: root.current && root.current.audio ? root.current.audio.muted : false
    readonly property real volume: root.current && root.current.audio ? root.current.audio.volume : 0
    readonly property string displayName: root.current
        ? (root.current.description !== "" ? root.current.description : root.current.name) : ""

    function switchTo(node) {
        if (root.isOutput) Pipewire.preferredDefaultAudioSink = node
        else Pipewire.preferredDefaultAudioSource = node
    }

    function dragSet(x) {
        if (!root.current || !root.current.audio) return
        root.current.audio.volume = Math.max(0, Math.min(1, x / track.width))
    }

    Text {
        Layout.fillWidth: true
        elide: Text.ElideRight
        text: root.label + (root.displayName !== "" ? "  ·  " + root.displayName : "")
        color: theme.mid
        font.family: "JetBrains Mono"
        font.pixelSize: 12
        font.bold: true
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Rectangle {
            implicitWidth: 20
            implicitHeight: 20
            radius: 4
            color: root.muted ? Qt.rgba(theme.red.r, theme.red.g, theme.red.b, 0.18) : "transparent"

            Text {
                anchors.centerIn: parent
                text: root.muted ? "×" : "•"
                color: root.muted ? theme.red : theme.mid
                font.family: "JetBrains Mono"
                font.pixelSize: 13
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: if (root.current && root.current.audio) root.current.audio.muted = !root.current.audio.muted
            }
        }

        Rectangle {
            id: track
            Layout.fillWidth: true
            implicitHeight: 6
            radius: 3
            color: Qt.rgba(theme.fg.r, theme.fg.g, theme.fg.b, 0.12)

            Rectangle {
                width: track.width * Math.min(1, root.volume)
                height: track.height
                radius: 3
                color: root.muted ? theme.dim : theme.mid
            }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                cursorShape: Qt.PointingHandCursor
                onPressed: mouse => root.dragSet(mouse.x)
                onPositionChanged: mouse => { if (pressed) root.dragSet(mouse.x) }
            }
        }

        Text {
            text: Math.round(root.volume * 100) + "%"
            color: theme.dim
            font.family: "JetBrains Mono"
            font.pixelSize: 11
            Layout.preferredWidth: 32
        }
    }

    Repeater {
        model: root.devices.filter(d => d !== root.current)

        Rectangle {
            id: row
            required property var modelData
            Layout.fillWidth: true
            implicitHeight: 24
            radius: 4
            color: hoverArea.containsMouse ? Qt.rgba(theme.fg.r, theme.fg.g, theme.fg.b, 0.08) : "transparent"

            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.right: parent.right
                anchors.rightMargin: 8
                elide: Text.ElideRight
                text: row.modelData.description !== "" ? row.modelData.description : row.modelData.name
                color: theme.mid
                font.family: "JetBrains Mono"
                font.pixelSize: 12
            }

            MouseArea {
                id: hoverArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.switchTo(row.modelData)
            }
        }
    }

    Text {
        visible: root.devices.length === 0
        text: "No devices found"
        color: theme.dim
        font.family: "JetBrains Mono"
        font.pixelSize: 12
    }
}
