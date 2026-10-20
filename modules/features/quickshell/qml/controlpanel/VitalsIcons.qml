import QtQuick
import QtQuick.Layouts

// CPU + RAM glyphs, yellow at 75% and red at 90%
RowLayout {
    id: root

    required property var vitals

    spacing: 8

    component Glyph: Item {
        property alias text: label.text
        property alias color: label.color

        implicitWidth: 16
        implicitHeight: 12

        Text {
            id: label
            anchors.centerIn: parent
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 14
        }
    }

    // Nerd Font glyphs (Material Design set), written as UTF-16 surrogate
    // pairs because they sit above U+FFFF:
    //   nf-md-chip   U+F061A
    //   nf-md-memory U+F035B
    Glyph { text: "󰘚"; color: root.vitals.cpuColor }
    Glyph { text: "󰍛"; color: root.vitals.memColor }
}
