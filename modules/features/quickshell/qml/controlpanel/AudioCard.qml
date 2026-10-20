import QtQuick
import QtQuick.Layouts
import qs

// Audio section: output and input
ColumnLayout {
    id: root

    required property var audio

    spacing: 10

    Theme { id: theme }

    Text {
        text: "Audio"
        color: theme.fg
        font.family: "JetBrains Mono"
        font.pixelSize: 14
        font.bold: true
    }

    AudioChannel {
        Layout.fillWidth: true
        label: "Output"
        isOutput: true
        devices: root.audio.sinks
        current: root.audio.sink
    }

    AudioChannel {
        Layout.fillWidth: true
        label: "Input"
        isOutput: false
        devices: root.audio.sources
        current: root.audio.source
    }
}
