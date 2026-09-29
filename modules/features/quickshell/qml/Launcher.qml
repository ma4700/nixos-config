import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// wofi-style app launcher: type to filter, Enter launches, Esc / click outside closes.
PanelWindow {
    id: panel
    property var results: []
    signal closeRequested()

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "launcher"
    // exclusive so typing works immediately without clicking into the box
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusiveZone: 0

    anchors {
        top: true
        right: true
        bottom: true
        left: true
    }

    color: "transparent"

    Theme { id: theme }

    readonly property int rowHeight: 30
    readonly property int maxRows: 8

    function refresh() {
        const q = input.text.trim().toLowerCase();
        let apps = DesktopEntries.applications.values.filter(e => !e.noDisplay);

        if (q === "") {
            apps = apps.slice().sort((a, b) => a.name.localeCompare(b.name));
        } else {
            const scored = [];
            for (const e of apps) {
                const name = e.name.toLowerCase();
                let score = -1;
                if (name.startsWith(q)) score = 0;
                else if (name.includes(q)) score = 1;
                else if ((e.keywords || []).join(" ").toLowerCase().includes(q)
                         || (e.genericName || "").toLowerCase().includes(q)) score = 2;
                if (score >= 0) scored.push({ e, score });
            }
            scored.sort((a, b) => a.score - b.score || a.e.name.localeCompare(b.e.name));
            apps = scored.map(s => s.e);
        }

        results = apps;
        list.currentIndex = 0;
    }

    function launch(entry) {
        if (!entry) return;
        if (entry.runInTerminal) Quickshell.execDetached(["kitty", "-e"].concat(entry.command));
        else entry.execute();
        panel.closeRequested();
    }

    onVisibleChanged: {
        if (visible) {
            input.text = "";
            refresh();
            input.forceActiveFocus();
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: panel.closeRequested()
    }

    Rectangle {
        id: box
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: parent.height * 0.22

        width: 420
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

            // search field
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 34
                radius: 4
                color: Qt.rgba(theme.fg.r, theme.fg.g, theme.fg.b, 0.06)

                TextInput {
                    id: input
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    verticalAlignment: TextInput.AlignVCenter
                    color: theme.bright
                    selectionColor: theme.dim
                    selectedTextColor: theme.bright
                    font.family: "JetBrains Mono"
                    font.pixelSize: 14
                    clip: true

                    onTextChanged: panel.refresh()

                    Keys.onPressed: event => {
                        const ctrl = event.modifiers & Qt.ControlModifier;
                        if (event.key === Qt.Key_Escape) {
                            panel.closeRequested();
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            panel.launch(panel.results[list.currentIndex]);
                        } else if (event.key === Qt.Key_Down || (ctrl && (event.key === Qt.Key_J || event.key === Qt.Key_N))) {
                            list.currentIndex = Math.min(list.currentIndex + 1, panel.results.length - 1);
                        } else if (event.key === Qt.Key_Up || (ctrl && (event.key === Qt.Key_K || event.key === Qt.Key_P))) {
                            list.currentIndex = Math.max(list.currentIndex - 1, 0);
                        } else {
                            return;
                        }
                        event.accepted = true;
                    }
                }

                Text {
                    visible: input.text.length === 0
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    text: "Search apps"
                    color: theme.dim
                    font.family: "JetBrains Mono"
                    font.pixelSize: 14
                }
            }

            Text {
                visible: panel.results.length === 0
                text: "No matches"
                color: theme.dim
                font.family: "JetBrains Mono"
                font.pixelSize: 13
            }

            ListView {
                id: list
                Layout.fillWidth: true
                implicitHeight: Math.min(panel.results.length, panel.maxRows) * (panel.rowHeight + spacing) - spacing
                visible: panel.results.length > 0
                clip: true
                spacing: 2
                model: panel.results
                currentIndex: 0
                highlightMoveDuration: 0

                delegate: Rectangle {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool selected: ListView.isCurrentItem
                    width: list.width
                    height: panel.rowHeight
                    radius: 4
                    color: selected ? Qt.rgba(theme.fg.r, theme.fg.g, theme.fg.b, 0.12) : "transparent"

                    Text {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        verticalAlignment: Text.AlignVCenter
                        text: row.modelData.name
                        color: row.selected ? theme.bright : theme.mid
                        font.family: "JetBrains Mono"
                        font.pixelSize: 13
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: list.currentIndex = row.index
                        onClicked: panel.launch(row.modelData)
                    }
                }
            }
        }
    }
}
