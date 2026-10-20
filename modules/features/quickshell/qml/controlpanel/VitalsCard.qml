import QtQuick
import QtQuick.Layouts
import qs

// CPU and Memory sections: big percentage plus details each
ColumnLayout {
    id: root

    required property var vitals

    spacing: 16

    component StatBlock: ColumnLayout {
        id: block

        property string title: ""
        property real pct: 0
        property color pctColor: "transparent"
        property var rows: []

        spacing: 8

        Theme { id: theme }

        Text {
            text: block.title
            color: theme.fg
            font.family: "JetBrains Mono"
            font.pixelSize: 14
            font.bold: true
            Layout.fillWidth: true
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: info.implicitHeight + 16
            radius: 4
            color: Qt.rgba(theme.fg.r, theme.fg.g, theme.fg.b, 0.06)

            ColumnLayout {
                id: info
                anchors.fill: parent
                anchors.margins: 8
                spacing: 4

                Text {
                    text: Math.round(block.pct) + "%"
                    color: block.pctColor
                    font.family: "JetBrains Mono"
                    font.pixelSize: 18
                    font.bold: true
                }

                InfoRows {
                    Layout.fillWidth: true
                    rows: block.rows
                }
            }
        }
    }

    StatBlock {
        Layout.fillWidth: true
        title: "CPU"
        pct: root.vitals.cpuPct
        pctColor: root.vitals.cpuColor
        rows: root.vitals.cpuRows
    }

    StatBlock {
        Layout.fillWidth: true
        title: "Memory"
        pct: root.vitals.memPct
        pctColor: root.vitals.memColor
        rows: root.vitals.ramRows
    }
}
