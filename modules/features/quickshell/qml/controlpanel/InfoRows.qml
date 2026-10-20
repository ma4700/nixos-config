import QtQuick
import QtQuick.Layouts
import qs

// label / value lines; each row is [label, value] or [label, value, color]
ColumnLayout {
    id: root

    property var rows: []
    property int labelWidth: 72
    property bool wrap: true      // false: one line each, elided

    spacing: 4

    Theme { id: theme }

    Repeater {
        model: root.rows

        RowLayout {
            id: line
            required property var modelData
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: line.modelData[0]
                color: theme.mid
                font.family: "JetBrains Mono"
                font.pixelSize: 12
                Layout.preferredWidth: root.labelWidth
                Layout.alignment: Qt.AlignTop
            }

            Text {
                text: line.modelData[1]
                color: line.modelData.length > 2 ? line.modelData[2] : theme.fg
                font.family: "JetBrains Mono"
                font.pixelSize: 12
                wrapMode: root.wrap ? Text.WrapAnywhere : Text.NoWrap
                elide: root.wrap ? Text.ElideNone : Text.ElideRight
                Layout.fillWidth: true
            }
        }
    }
}
