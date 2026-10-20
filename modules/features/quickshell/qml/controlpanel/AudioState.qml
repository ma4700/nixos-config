import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

// PipeWire through Quickshell's native module, event-driven
Scope {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property bool sinkMuted: root.sink && root.sink.audio ? root.sink.audio.muted : false
    readonly property real sinkVol: root.sink && root.sink.audio ? root.sink.audio.volume : 0
    readonly property bool sourceMuted: root.source && root.source.audio ? root.source.audio.muted : false
    readonly property real sourceVol: root.source && root.source.audio ? root.source.audio.volume : 0

    readonly property var sinks: Pipewire.nodes.values.filter(n => n.audio && n.isSink && !n.isStream)
    readonly property var sources: Pipewire.nodes.values.filter(n => n.audio && !n.isSink && !n.isStream)

    function pct(v) { return Math.round(v * 100) + "%" }

    // binding every device to use their .audio properties
    PwObjectTracker {
        objects: [root.sink, root.source].concat(root.sinks, root.sources)
    }
}
