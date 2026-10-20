import Quickshell
import Quickshell.Wayland
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes

// Battery icon + panel, and the low-battery / UPS notifications.
// Hides itself when there is no battery, so on a desktop it takes no space.
Item {
    id: bat

    Theme { id: theme }

    readonly property var dev: UPower.displayDevice
    // Only a real battery counts. UPower's combined display device can also
    // reflect a UPS, so check that a device of type Battery actually exists.
    readonly property bool hasBattery: {
        for (const d of UPower.devices.values)
            if (d.type === UPowerDeviceType.Battery && d.isPresent) return true
        return false
    }
    readonly property bool present: dev.ready && dev.isPresent && hasBattery
    readonly property real pct: dev.percentage * 100   // UPower gives 0..1
    readonly property bool charging: dev.state === UPowerDeviceState.Charging

    readonly property color colWarn: theme.yellow
    readonly property color colCrit: theme.red
    readonly property color colCharge: theme.green

    readonly property color fillColor: charging ? colCharge
        : pct < 10 ? colCrit
        : pct < 20 ? colWarn
        : theme.mid

    property bool hoverShown: false   // tooltip mode: follows the cursor, click-through
    property bool pinned: false       // click mode: fullscreen closer, click anywhere / Esc dismisses
    property real iconX: 0            // icon centre in screen coords
    property bool suppressHover: false

    readonly property bool shown: present && (pinned || hoverShown)

    visible: present
    implicitWidth: 22
    implicitHeight: 10

    function fmtTime(s) {
        if (!s || s <= 0) return ""
        const h = Math.floor(s / 3600), m = Math.round((s % 3600) / 60)
        return h > 0 ? h + "h " + m + "m" : m + "m"
    }

    function captureX() {
        iconX = bat.mapToItem(null, bat.width / 2, 0).x
    }

    function dismiss() {
        pinned = false
        hoverShown = false
        // the fullscreen closer vanishes under the cursor; without this the
        // icon would instantly see "hover" again and reopen the tooltip
        suppressHover = true
        suppressTimer.restart()
    }

    Timer {
        id: suppressTimer
        interval: 400
        onTriggered: bat.suppressHover = false
    }

    // ---- low-battery notifications -------------------------------------
    // Event-driven: UPower only emits a change now and then, and this only
    // runs on those changes (no timers, no polling). Goes through
    // notify-send, so it lands in our own NotificationServer and gets the
    // normal/critical styling.
    readonly property int lowAt: 20
    readonly property int critAt: 10
    property bool warnedLow: false
    property bool warnedCrit: false

    function check() {
        if (!present || pct <= 0) return
        const p = Math.round(pct)
        // re-arm once the level has climbed back above each threshold
        if (p > lowAt) warnedLow = false
        if (p > critAt) warnedCrit = false
        if (dev.state !== UPowerDeviceState.Discharging) return

        if (p <= critAt && !warnedCrit) {
            warnedCrit = true
            warnedLow = true    // don't also send the 20% one afterwards
            Quickshell.execDetached(["notify-send", "-u", "critical", "-a", "battery",
                "Battery critical", p + "% remaining, plug in the charger"])
        } else if (p <= lowAt && !warnedLow) {
            warnedLow = true
            Quickshell.execDetached(["notify-send", "-u", "normal", "-a", "battery",
                "Battery low", p + "% remaining"])
        }
    }

    onPctChanged: check()
    onPresentChanged: check()
    onChargingChanged: check()   // also fires on unplug

    // ---- UPS failure -----------------------------------------------------
    // Normal notifications: UPS took over (mains lost), power restored, UPS working
    // again after a failure. Each fires once per event.
    // A UPS is "failed" when it reports empty or not present, or when one we
    // had seen disappears from UPower. Notified once per failure, critical.
    // Independent of the battery icon, so it also works on a desktop where
    // the battery widget is hidden.
    property var knownUps: ({})    // id -> display name
    property var failedUps: ({})   // id -> already notified
    property var onUps: ({})       // id -> currently running on the UPS battery

    function notifyUps(name, why) {
        Quickshell.execDetached(["notify-send", "-u", "critical", "-a", "ups",
            name + " offline", why])
    }

    function checkUps() {
        const seen = {}
        for (const d of UPower.devices.values) {
            if (d.type !== UPowerDeviceType.Ups) continue
            const id = d.nativePath || d.model || "ups"
            const name = d.model || "UPS"
            seen[id] = true
            knownUps[id] = name
            const empty = d.state === UPowerDeviceState.Empty
            const bad = !d.isPresent || empty
            const discharging = d.state === UPowerDeviceState.Discharging
            const recovered = !bad && failedUps[id]

            if (recovered) {
                // was failed, now working again
                failedUps[id] = false
                onUps[id] = discharging
                Quickshell.execDetached(["notify-send", "-u", "normal", "-a", "ups",
                    name + " back online", "The UPS is working again"])
            } else if (bad) {
                if (!failedUps[id]) {
                    failedUps[id] = true
                    notifyUps(name, empty ? "The UPS battery is empty" : "The UPS is no longer reporting")
                }
            } else if (discharging) {
                // mains lost, UPS took over
                if (!onUps[id]) {
                    onUps[id] = true
                    Quickshell.execDetached(["notify-send", "-u", "normal", "-a", "ups",
                        "Running on " + name, "Mains power lost, the UPS has taken over"])
                }
            } else if (onUps[id]) {
                // no longer discharging and not failed: mains is back
                onUps[id] = false
                Quickshell.execDetached(["notify-send", "-u", "normal", "-a", "ups",
                    "Power restored", "Mains power is back, " + name + " is charging"])
            }
        }
        for (const id in knownUps) {
            if (!seen[id] && !failedUps[id]) {
                failedUps[id] = true
                notifyUps(knownUps[id], "The UPS disconnected")
            }
        }
    }

    Component.onCompleted: checkUps()

    // device added/removed
    Connections {
        target: UPower.devices
        function onValuesChanged() { bat.checkUps() }
    }

    // state / presence changes of each device (watched via bindings)
    Instantiator {
        model: UPower.devices
        delegate: QtObject {
            required property var modelData
            readonly property int st: modelData.state
            readonly property bool here: modelData.isPresent
            onStChanged: bat.checkUps()
            onHereChanged: bat.checkUps()
        }
    }

    // Battery body
    Rectangle {
        id: body
        width: 18; height: 10
        anchors.verticalCenter: parent.verticalCenter
        radius: 2
        color: "transparent"
        border.width: 1
        border.color: bat.fillColor

        // Charge level
        Rectangle {
            x: 2; y: 2
            height: parent.height - 4
            width: Math.max(0, (parent.width - 4) * Math.min(bat.pct, 100) / 100)
            radius: 1
            color: bat.fillColor
        }

    // When charging
        Shape {
            visible: bat.charging
            anchors.centerIn: parent
            width: 8; height: 10
            scale: 0.7
            ShapePath {
                fillColor: theme.fg
                strokeColor: bat.colCharge
                strokeWidth: 0.8
                PathPolyline {
                    path: [
                        Qt.point(5, 0), Qt.point(0, 6), Qt.point(3.5, 6),
                        Qt.point(2.5, 10), Qt.point(8, 3.5), Qt.point(4.5, 3.5),
                        Qt.point(5, 0)
                    ]
                }
            }
        }
    }

    // Terminal nub
    Rectangle {
        x: body.width + 1; width: 2; height: 4
        anchors.verticalCenter: parent.verticalCenter
        radius: 1
        color: bat.fillColor
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: {
            if (bat.suppressHover) return
            bat.captureX()
            bat.hoverShown = true
        }
        onExited: bat.hoverShown = false
        onClicked: {
            bat.captureX()
            bat.pinned = true
        }
    }

    // fully click-through while hovering (empty input region)
    Region { id: passThrough }

    // Same structure as NotificationCenter: fullscreen window + inner box
    PanelWindow {
        id: overlay
        visible: bat.shown

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "battery-info"
        WlrLayershell.keyboardFocus: bat.pinned ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        exclusiveZone: 0

        anchors {
            top: true
            right: true
            bottom: true
            left: true
        }

        color: "transparent"

        // hover: input passes straight through, so it can't steal the pointer
        // and the tooltip goes away as soon as the cursor leaves the icon.
        // pinned: full input so a click anywhere dismisses it.
        mask: bat.pinned ? null : passThrough

        Keys.onEscapePressed: bat.dismiss()

        MouseArea {
            anchors.fill: parent
            enabled: bat.pinned
            onClicked: bat.dismiss()
        }

        Rectangle {
            id: box
            y: 10
            x: Math.max(10, Math.min(overlay.width - width - 10, bat.iconX - width / 2))

            width: 200
            height: contentCol.implicitHeight + 24
            radius: 4
            color: Qt.rgba(theme.bg.r, theme.bg.g, theme.bg.b, 0.92)

            // swallows clicks so they don't fall through to the fullscreen closer
            MouseArea {
                anchors.fill: parent
                onClicked: {}
            }

            ColumnLayout {
                id: contentCol
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                Text {
                    text: "Battery"
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
                        spacing: 2

                        Text {
                            text: Math.round(bat.pct) + "%"
                            color: bat.fillColor
                            font.family: "JetBrains Mono"
                            font.pixelSize: 18
                            font.bold: true
                        }

                        Text {
                            text: bat.charging ? "Charging"
                                : bat.dev.state === UPowerDeviceState.FullyCharged ? "Fully charged"
                                : "On battery"
                            color: theme.fg
                            font.family: "JetBrains Mono"
                            font.pixelSize: 13
                        }

                        Text {
                            readonly property string t: bat.charging
                                ? bat.fmtTime(bat.dev.timeToFull)
                                : bat.fmtTime(bat.dev.timeToEmpty)
                            visible: t !== ""
                            text: t + (bat.charging ? " until full" : " remaining")
                            color: theme.mid
                            font.family: "JetBrains Mono"
                            font.pixelSize: 12
                        }
                    }
                }
            }
        }
    }
}
