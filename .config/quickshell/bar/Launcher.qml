import qs
import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

BasePanel {
    id: launcher

    ipcTarget: "launcher"
    placeholder: "Search applications..."

    cardWidth: 480
    cardHeight: Math.min(600, 74 + filteredApps.length * 50)

    searchHeight: 44
    columnSpacing: 8
    searchFontSize: 14
    searchIconSize: 16

    maxIndex: Math.max(filteredApps.length - 1, 0)

    readonly property var allApps: DesktopEntries.applications.values
    readonly property string query: searchText.toLowerCase()
    readonly property var filteredApps: {
        const named = allApps.filter(app => app.name)

        if (query === "") return named.slice().sort((a, b) => a.name.localeCompare(b.name))

        const q = query
        return named.filter(app => app.name.toLowerCase().includes(q)).sort((a, b) => {
            const aStarts = a.name.toLowerCase().startsWith(q)
            const bStarts = b.name.toLowerCase().startsWith(q)
            if (aStarts && !bStarts) return -1
            if (!aStarts && bStarts) return 1
            return a.name.localeCompare(b.name)
        })
    }

    onSearchEdited: selectedIndex = 0

    onAccepted: (index) => launcher.launch(filteredApps[index])

    function launch(app) {
        if (!app) return
        if (app.runInTerminal) {
            Quickshell.execDetached({
                command: ["/usr/bin/alacritty", "-e"].concat(app.command),
                workingDirectory: app.workingDirectory
            })
        } else {
            app.execute()
        }
        close()
    }

    function resolveIcon(name) {
        if (!name) return ""
        const primary = Quickshell.iconPath(name, true)
        if (primary !== "") return primary
        return Quickshell.iconPath("application-x-executable", true)
    }

    ListView {
        id: appList
        anchors.fill: parent
        model: filteredApps
        clip: true
        currentIndex: selectedIndex
        spacing: 2

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }

        onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

        delegate: Rectangle {
            required property var modelData
            required property int index

            width: appList.width
            height: 48
            radius: 8
            color: index === selectedIndex
                ? Theme.hexToRgba(Theme.color4, 0.7)
                : (appHover.hovered ? Theme.hexToRgba(Theme.foreground, 0.07) : "transparent")

            Behavior on color {
                ColorAnimation { duration: 100 }
            }

            HoverHandler {
                id: appHover
                onHoveredChanged: if (hovered) selectedIndex = index
            }

            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: 12
                    rightMargin: 12
                }
                spacing: 12

                IconImage {
                    id: iconImg
                    source: launcher.resolveIcon(modelData.icon)
                    implicitSize: 28
                    asynchronous: true
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        text: modelData.name
                        color: index === selectedIndex
                            ? Theme.background
                            : Theme.foreground
                        font.pixelSize: 13
                        font.bold: index === selectedIndex
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: modelData.genericName || modelData.comment || ""
                        color: index === selectedIndex
                            ? Theme.hexToRgba(Theme.background, 0.7)
                            : Theme.hexToRgba(Theme.foreground, 0.5)
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        visible: text !== ""
                    }
                }
            }

            TapHandler {
                onTapped: launcher.launch(modelData)
            }
        }
    }
}
