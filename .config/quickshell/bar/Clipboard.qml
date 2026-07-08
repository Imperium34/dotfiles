import qs
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

BasePanel {
    id: clipboard

    ipcTarget: "clipboard"
    placeholder: "Search clipboard..."

    cardWidth: 420
    cardHeight: Math.min(500, 106 + Math.max(1, filteredEntries.length) * 34)

    searchHeight: 40
    columnSpacing: 6
    searchFontSize: 13
    searchIconSize: 14

    maxIndex: filteredEntries.length

    property var entries: []

    readonly property string query: searchText.toLowerCase()
    readonly property var filteredEntries: {
        if (query === "") return entries
        return entries.filter(e => e.content.toLowerCase().includes(query))
    }

    onOpened: loadProc.running = true

    onSearchEdited: selectedIndex = (searchText !== "" && filteredEntries.length > 0) ? 1 : 0

    onAccepted: (index) => {
        if (filteredEntries.length === 0) return
        if (index === 0) {
            clearProc.running = true
            close()
        } else {
            paste(filteredEntries[index - 1])
        }
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

    ListView {
        id: clipList
        anchors.fill: parent
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
