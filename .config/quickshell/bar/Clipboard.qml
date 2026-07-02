import qs
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

PanelWindow {
    id: clipboard

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    exclusiveZone: 0
    color: "transparent"
    property bool isFocused: false
    WlrLayershell.keyboardFocus: isFocused ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.layer: WlrLayer.Overlay
    visible: false

    property bool animIn: false
    property int selectedIndex: 0
    property var entries: []

    function open() {
        isFocused = true
        visible = true
        animIn = true
        searchField.text = ""
        selectedIndex = 0
        loadProc.running = true
        Qt.callLater(() => searchField.forceActiveFocus())
    }

    function close() {
        isFocused = false
        animIn = false
        closeTimer.start()
    }

    Timer {
        id: closeTimer
        interval: 200
        onTriggered: clipboard.visible = false
    }

    Process {
        id: loadProc
        command: ["/usr/bin/cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n").filter(l => l.length > 0)
                clipboard.entries = lines.map(line => {
                    const tab = line.indexOf("\t")
                    return {
                        id: tab >= 0 ? line.substring(0, tab) : line,
                        content: tab >= 0 ? line.substring(tab + 1) : line,
                        raw: line
                    }
                })
            }
        }
    }

    Process {
        id: clearProc
        command: ["/usr/bin/cliphist", "wipe"]
        onRunningChanged: {
            if (!running) {
                notifyProc.running = true
                clipboard.entries = []
            }
        }
    }

    Process {
        id: notifyProc
        command: ["/usr/bin/notify-send", "Clipboard", "History cleared successfully"]
    }

    readonly property string query: searchField.text.toLowerCase()
    readonly property var filteredEntries: {
        if (query === "") return entries
        return entries.filter(e => e.content.toLowerCase().includes(query))
    }

    function paste(entry) {
        if (!entry) return
        const safeRaw = entry.raw.replace(/'/g, "'\\''")
        Quickshell.execDetached([
            "/usr/bin/bash", "-c",
            "printf '%s\\n' '" + safeRaw + "' | /usr/bin/cliphist decode | /usr/bin/wl-copy"
        ])
        close()
    }

    IpcHandler {
        target: "clipboard"
        function toggle(): void {
            if (clipboard.visible) clipboard.close()
            else clipboard.open()
        }
    }

    HyprlandFocusGrab {
        id: focusGrab
        windows: [clipboard]
        onCleared: clipboard.close()
    }

    TapHandler {
        onTapped: clipboard.close()
    }

    Item {
        id: card
        anchors.centerIn: parent
        width: 420
        height: Math.min(500, 106 + Math.max(1, filteredEntries.length) * 34)

        opacity: animIn ? 1 : 0
        scale: animIn ? 1 : 0.96
        transformOrigin: Item.Center

        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
        Behavior on height {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }

        Rectangle {
            anchors.fill: parent
            radius: 16
            color: Theme.hexToRgba(Theme.background, 0.95)
            border.color: Theme.hexToRgba(Theme.foreground, 0.1)
            border.width: 1

            ColumnLayout {
                anchors {
                    fill: parent
                    margins: 12
                }
                spacing: 6

                Rectangle {
                    Layout.fillWidth: true
                    height: 40
                    radius: 10
                    color: Theme.hexToRgba(Theme.foreground, 0.07)
                    border.color: searchField.activeFocus
                        ? Theme.hexToRgba(Theme.color4, 0.8)
                        : Theme.hexToRgba(Theme.foreground, 0.1)
                    border.width: 1

                    Behavior on border.color {
                        ColorAnimation { duration: 150 }
                    }

                    RowLayout {
                        anchors {
                            fill: parent
                            leftMargin: 12
                            rightMargin: 12
                        }
                        spacing: 8

                        Text {
                            text: "󰍉"
                            color: Theme.hexToRgba(Theme.foreground, 0.5)
                            font.pixelSize: 14
                            font.family: "Symbols Nerd Font"
                        }
        
                        TextInput {
                            id: searchField
                            Layout.fillWidth: true
                            color: Theme.foreground
                            font.pixelSize: 13
                            selectionColor: Theme.hexToRgba(Theme.color4, 0.4)
                            selectedTextColor: Theme.foreground
                            clip: true
                            selectByMouse: true

                            onTextChanged: selectedIndex = (text !== "" && filteredEntries.length > 0) ? 1 : 0

                            Keys.onUpPressed: (event) => {
                                event.accepted = true
                                selectedIndex = Math.max(0, selectedIndex - 1)
                            }
                            
                            Keys.onDownPressed: (event) => {
                                event.accepted = true
                                selectedIndex = Math.min(filteredEntries.length, selectedIndex + 1)
                            }
                            
                            Keys.onReturnPressed: (event) => {
                                event.accepted = true
                                if (filteredEntries.length === 0) return
                                if (selectedIndex === 0) {
                                    clearProc.running = true
                                    close()
                                } else {
                                    paste(filteredEntries[selectedIndex - 1])
                                }
                            }
                            
                            Keys.onEscapePressed: (event) => {
                                event.accepted = true
                                clipboard.close()
                            }

                            Text {
                                anchors.fill: parent
                                text: "Search clipboard..."
                                color: Theme.hexToRgba(Theme.foreground, 0.3)
                                font.pixelSize: 13
                                visible: searchField.text === ""
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                }

                ListView {
                    id: clipList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    currentIndex: selectedIndex
                    spacing: 2

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                    }

                    onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                    Text {
                        anchors.centerIn: parent
                        text: query !== "" ? "No matches found" : "Clipboard is empty"
                        color: Theme.hexToRgba(Theme.foreground, 0.4)
                        font.pixelSize: 13
                        visible: filteredEntries.length === 0
                    }

                    header: Rectangle {
                        width: clipList.width
                        height: 36
                        radius: 8
                        visible: filteredEntries.length > 0
                        color: selectedIndex === 0
                            ? Theme.hexToRgba(Theme.color1, 0.7)
                            : (clearHover.hovered ? Theme.hexToRgba(Theme.foreground, 0.07) : "transparent")

                        Behavior on color {
                            ColorAnimation { duration: 100 }
                        }

                        HoverHandler {
                            id: clearHover
                            onHoveredChanged: if (hovered) selectedIndex = 0
                        }

                        RowLayout {
                            anchors {
                                fill: parent
                                leftMargin: 12
                                rightMargin: 12
                            }
                            spacing: 8

                            Text {
                                text: "󰃢"
                                color: selectedIndex === 0 ? Theme.background : Theme.color1
                                font.pixelSize: 14
                                font.family: "Symbols Nerd Font"
                            }

                            Text {
                                text: "Clear History"
                                color: selectedIndex === 0 ? Theme.background : Theme.color1
                                font.pixelSize: 13
                                font.bold: selectedIndex === 0
                            }
                        }

                        TapHandler {
                            onTapped: {
                                clearProc.running = true
                                clipboard.close()
                            }
                        }
                    }

                    model: filteredEntries

                    delegate: Rectangle {
                        id: entryRect
                        required property var modelData
                        required property int index

                        width: clipList.width
                        height: 32
                        radius: 8

                        property bool flashing: false

                        color: flashing
                            ? Theme.hexToRgba(Theme.color5, 0.4)
                            : ((index + 1) === selectedIndex
                                ? Theme.hexToRgba(Theme.color4, 0.7)
                                : (entryHover.hovered
                                    ? Theme.hexToRgba(Theme.foreground, 0.07)
                                    : "transparent"))

                        Behavior on color {
                            ColorAnimation { duration: 100 }
                        }

                        readonly property bool isImage: modelData.content.startsWith("[[")
                        readonly property bool isPath: modelData.content.startsWith("/") || modelData.content.startsWith("~/")
                        readonly property bool isUrl: modelData.content.startsWith("http://") || modelData.content.startsWith("https://")
                        readonly property bool isCode: modelData.content.startsWith("$") || modelData.content.includes("{") || modelData.content.includes("()")

                        readonly property color accentColor: {
                            if (isImage) return Theme.color3
                            if (isUrl)   return Theme.color6
                            if (isPath)  return Theme.color5
                            if (isCode)  return Theme.color2
                            return Theme.hexToRgba(Theme.foreground, 0.2)
                        }

                        HoverHandler {
                            id: entryHover
                            onHoveredChanged: if (hovered) selectedIndex = index + 1
                        }

                        RowLayout {
                            anchors.fill: parent
                            spacing: 0

                            Rectangle {
                                width: 3
                                height: parent.height * 0.6
                                radius: 2
                                color: accentColor
                                Layout.leftMargin: 6
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Text {
                                Layout.fillWidth: true
                                Layout.leftMargin: 8
                                Layout.rightMargin: 8
                                verticalAlignment: Text.AlignVCenter

                                text: isImage ? "  Image" : modelData.content
                                color: (index + 1) === selectedIndex
                                    ? Theme.background
                                    : (isImage ? Theme.color3 : Theme.foreground)
                                font.pixelSize: 12
                                font.family: isImage ? "Symbols Nerd Font" : "Departure Mono"
                                elide: Text.ElideRight
                            }

                            Text {
                                text: "#" + (index + 1)
                                color: (index + 1) === selectedIndex
                                    ? Theme.hexToRgba(Theme.background, 0.5)
                                    : Theme.hexToRgba(Theme.foreground, 0.25)
                                font.pixelSize: 10
                                font.family: "Departure Mono"
                                Layout.rightMargin: 10
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }

                        TapHandler {
                            onTapped: {
                                entryRect.flashing = true
                                flashTimer.start()
                            }
                        }

                        Timer {
                            id: flashTimer
                            interval: 120
                            onTriggered: {
                                entryRect.flashing = false
                                clipboard.paste(modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}
