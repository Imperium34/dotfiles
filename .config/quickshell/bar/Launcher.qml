import qs
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

PanelWindow {
    id: launcher

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    exclusiveZone: 0
    color: "transparent"
    property bool isFocused: false
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: isFocused ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    visible: false

    property bool animIn: false
    property int selectedIndex: 0

    function open() {
        isFocused = true
        visible = true
        animIn = true
        searchField.text = ""
        searchField.forceActiveFocus()
        selectedIndex = 0
    }

    function close() {
        isFocused = false
        animIn = false
        closeTimer.start()
    }

    Timer {
        id: closeTimer
        interval: 200
        onTriggered: launcher.visible = false
    }

    readonly property var allApps: DesktopEntries.applications.values
    readonly property string query: searchField.text.toLowerCase()
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

    IpcHandler {
        target: "launcher"
        function toggle(): void {
            if (launcher.visible) launcher.close()
            else launcher.open()
        }
        function open(): void { launcher.open() }
        function close(): void { launcher.close() }
    }

    HyprlandFocusGrab {
        id: focusGrab
        windows: [launcher]
        onCleared: launcher.close()
    }

    TapHandler {
        onTapped: launcher.close()
    }

    Item {
        id: card
        anchors.centerIn: parent
        width: 480
        height: Math.min(600, 74 + filteredApps.length * 50)

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
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    height: 44
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
                            font.pixelSize: 16
                            font.family: "Symbols Nerd Font"
                        }

                        TextInput {
                            id: searchField
                            Layout.fillWidth: true
                            color: Theme.foreground
                            font.pixelSize: 14
                            selectionColor: Theme.hexToRgba(Theme.color4, 0.4)
                            selectedTextColor: Theme.foreground
                            clip: true

                            onTextChanged: selectedIndex = 0

                            Keys.onUpPressed: (event) => {
                                event.accepted = true
                                selectedIndex = Math.max(0, selectedIndex - 1)
                            }

                            Keys.onDownPressed: (event) => {
                                event.accepted = true
                                selectedIndex = Math.min(Math.max(filteredApps.length - 1, 0), selectedIndex + 1)
                            }

                            Keys.onReturnPressed: (event) => {
                                event.accepted = true
                                launcher.launch(filteredApps[selectedIndex])
                            }

                            Keys.onEscapePressed: (event) => {
                                event.accepted = true
                                launcher.close()
                            }

                            Text {
                                anchors.fill: parent
                                text: "Search applications..."
                                color: Theme.hexToRgba(Theme.foreground, 0.3)
                                font.pixelSize: 14
                                visible: searchField.text === ""
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                }

                ListView {
                    id: appList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
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
        }
    }
}
