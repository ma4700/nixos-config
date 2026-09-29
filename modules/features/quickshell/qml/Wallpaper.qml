import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
    WlrLayershell.layer: WlrLayer.Background

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"

    WallpaperPath { id: wp }

    Image {
        anchors.fill: parent
        source: wp.path
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }
}
