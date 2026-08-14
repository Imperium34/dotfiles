import qs
import qs.components
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

BaseExpandPopup {
    id: clipboard

    ipcTarget: "clipboard"
    placeholder: "Search clipboard..."

    implicitWidth: 420
    implicitHeight: Math.min(500, 106 + Math.max(1, filteredEntries.length) * 34)

    searchHeight: 40
    columnSpacing: 6
    searchFontSize: 13
    searchIconSize: 14

    minIndex: entryList.minIndex
    maxIndex: entryList.maxIndex

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

    SelectableListView {
        id: entryList
        anchors.fill: parent
        model: clipboard.filteredEntries
        rowHeight: 32
        headerHeight: 36
        accentColor: Theme.color5
        headerAccentColor: Theme.color1
        emptyText: clipboard.query !== "" ? "No matches found" : "Clipboard is empty"

        onSelectedIndexChanged: if (clipboard.selectedIndex !== selectedIndex) clipboard.selectedIndex = selectedIndex
        Connections {
            target: clipboard
            function onSelectedIndexChanged() {
                if (entryList.selectedIndex !== clipboard.selectedIndex) entryList.selectedIndex = clipboard.selectedIndex
            }
        }

        header: Component {
            RowLayout {
                property bool selected: false
                anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                spacing: 8

                Text {
                    text: "󰃢"
                    color: selected ? Theme.background : Theme.color1
                    font.pixelSize: 14
                    font.family: "Symbols Nerd Font"
                }
                Text {
                    text: "Clear History"
                    color: selected ? Theme.background : Theme.color1
                    font.pixelSize: 13
                    font.bold: selected
                }

                TapHandler {
                    onTapped: {
                        clearProc.running = true
                        clipboard.close()
                    }
                }
            }
        }

        delegate: Component {
            Item {
                id: row
                property var modelData
                property int index
                property bool selected: false

                property bool flashing: false

                readonly property bool isImage: row.modelData.content.startsWith("[[")
                readonly property bool isPath: row.modelData.content.startsWith("/") || row.modelData.content.startsWith("~/")
                readonly property bool isUrl: row.modelData.content.startsWith("http://") || row.modelData.content.startsWith("https://")
                readonly property bool isCode: row.modelData.content.startsWith("$") || row.modelData.content.includes("{") || row.modelData.content.includes("()")

                readonly property color rowAccentColor: {
                    if (isImage) return Theme.color3
                    if (isUrl)   return Theme.color6
                    if (isPath)  return Theme.color5
                    if (isCode)  return Theme.color2
                    return Theme.hexToRgba(Theme.foreground, 0.2)
                }

                // Flash feedback overlays the shared selection highlight
                // briefly on tap, same as the original.
                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    color: Theme.hexToRgba(Theme.color5, 0.4)
                    opacity: row.flashing ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 100 } }
                }

                RowLayout {
                    anchors.fill: parent
                    spacing: 0

                    Rectangle {
                        width: 3
                        height: parent.height * 0.6
                        radius: 2
                        color: row.rowAccentColor
                        Layout.leftMargin: 6
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.leftMargin: 8
                        Layout.rightMargin: 8
                        verticalAlignment: Text.AlignVCenter

                        text: row.isImage ? "  Image" : row.modelData.content
                        color: row.selected
                            ? Theme.background
                            : (row.isImage ? Theme.color3 : Theme.foreground)
                        font.pixelSize: 12
                        font.family: row.isImage ? "Symbols Nerd Font" : "Departure Mono"
                        elide: Text.ElideRight
                    }

                    Text {
                        text: "#" + row.index
                        color: row.selected
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
                        row.flashing = true
                        flashTimer.start()
                    }
                }

                Timer {
                    id: flashTimer
                    interval: 120
                    onTriggered: {
                        row.flashing = false
                        clipboard.paste(row.modelData)
                    }
                }
            }
        }
    }
}
