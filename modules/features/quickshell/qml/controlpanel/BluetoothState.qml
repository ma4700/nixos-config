import Quickshell
import Quickshell.Bluetooth
import QtQuick

// BlueZ through Quickshell.Bluetooth, nothing polled.
// ControlPanel sets `enabled` from BluetoothFeature; while it is false the
// Bluetooth module is never touched.
Scope {
    id: root

    property bool enabled: false

    readonly property var adapter: root.enabled ? Bluetooth.defaultAdapter : null
    readonly property bool powered: root.adapter ? root.adapter.enabled : false
    readonly property bool scanning: root.adapter ? root.adapter.discovering : false

    readonly property var devices: root.enabled ? Bluetooth.devices.values : []
    readonly property var connectedDevices: root.devices.filter(d => d.connected)
    readonly property var knownDevices: root.devices.filter(d => d.bonded && !d.connected)
    readonly property var availableDevices: root.devices.filter(d => !d.bonded)

    function togglePower() {
        if (root.adapter) root.adapter.enabled = !root.adapter.enabled
    }

    // one-shot ~10s discovery, only from the refresh button
    function refresh() {
        if (!root.adapter || !root.adapter.enabled) return
        root.adapter.discovering = true
        scanStopTimer.restart()
    }

    Timer {
        id: scanStopTimer
        interval: 10000
        onTriggered: if (root.adapter) root.adapter.discovering = false
    }
}
