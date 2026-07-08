import qs
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: root

    // ---- public API ----
    property string ipcTarget: ""
    property string placeholder: "Search..."

    property int cardWidth: 440
    property int cardHeight: 300

    property int searchHeight: 42
    property int columnSpacing: 6
    property int searchFontSize: 13
    property int searchIconSize: 14

    // ---- motion tuning ----
    property int animEnter: 240
    property int animExit: 140
    property int riseDistance: 10
    property real animStartScale: 0.96
    property real scrimOpacity: 0.32

    property string layerNamespace: ipcTarget

    property int selectedIndex: 0
    property int minIndex: 0
    property int maxIndex: 0

    property alias searchText: searchField.text

    signal accepted(int index)
    signal searchEdited(string text)
    signal opened()

    default property alias content: contentSlot.data

    // ---- window / layershell ----
    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: false

    property bool isFocused: false
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: root.layerNamespace
    WlrLayershell.keyboardFocus: isFocused ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property bool animIn: false

    function open() {
        isFocused = true
        visible = true
        animIn = true
        searchField.text = ""
        selectedIndex = 0
        opened()
        Qt.callLater(() => searchField.forceActiveFocus())
    }

    function close() {
        isFocused = false
        animIn = false
        closeTimer.start()
    }

    Timer {
        id: closeTimer
        interval: root.animExit + 10
        onTriggered: root.visible = false
    }

    IpcHandler {
        target: root.ipcTarget
        function toggle(): void {
            if (root.visible && root.animIn) root.close()
            else root.open()
        }
        function open(): void { root.open() }
        function close(): void { root.close() }
    }

    HyprlandFocusGrab {
        id: focusGrab
        windows: [root]
        onCleared: root.close()
    }

    TapHandler {
        onTapped: root.close()
    }

    // ---- backdrop scrim ----
    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: root.visible ? root.scrimOpacity : 0

        Behavior on opacity {
            NumberAnimation {
                duration: root.animEnter
                easing.type: Easing.OutCubic
            }
        }
    }

    // ---- animated card ----
    Item {
        id: card
        anchors.centerIn: parent
        width: root.cardWidth
        height: root.cardHeight

        opacity: root.animIn ? 1 : 0
        scale: root.animIn ? 1 : root.animStartScale
        transformOrigin: Item.Center

        transform: Translate {
            y: root.animIn ? 0 : root.riseDistance
            Behavior on y {
                NumberAnimation {
                    duration: root.animIn ? root.animEnter : root.animExit
                    easing.type: root.animIn ? Easing.OutBack : Easing.InCubic
                    easing.overshoot: 1.1
                }
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: root.animIn ? root.animEnter : root.animExit
                easing.type: Easing.OutCubic
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: root.animIn ? root.animEnter : root.animExit
                easing.type: root.animIn ? Easing.OutBack : Easing.InCubic
                easing.overshoot: 1.1
            }
        }
        Behavior on height {
            NumberAnimation { duration: 90; easing.type: Easing.OutCubic }
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
                spacing: root.columnSpacing

                // ---- search box ----
                Rectangle {
                    Layout.fillWidth: true
                    height: root.searchHeight
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
                            font.pixelSize: root.searchIconSize
                            font.family: "Symbols Nerd Font"
                        }

                        TextInput {
                            id: searchField
                            Layout.fillWidth: true
                            color: Theme.foreground
                            font.pixelSize: root.searchFontSize
                            selectionColor: Theme.hexToRgba(Theme.color4, 0.4)
                            selectedTextColor: Theme.foreground
                            clip: true
                            selectByMouse: true

                            onTextChanged: root.searchEdited(text)

                            Keys.onUpPressed: (event) => {
                                event.accepted = true
                                root.selectedIndex = Math.max(root.minIndex, root.selectedIndex - 1)
                            }

                            Keys.onDownPressed: (event) => {
                                event.accepted = true
                                root.selectedIndex = Math.min(root.maxIndex, root.selectedIndex + 1)
                            }

                            Keys.onReturnPressed: (event) => {
                                event.accepted = true
                                root.accepted(root.selectedIndex)
                            }

                            Keys.onEscapePressed: (event) => {
                                event.accepted = true
                                root.close()
                            }

                            Text {
                                anchors.fill: parent
                                text: root.placeholder
                                color: Theme.hexToRgba(Theme.foreground, 0.3)
                                font.pixelSize: root.searchFontSize
                                visible: searchField.text === ""
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                }

                // ---- content slot ----
                Item {
                    id: contentSlot
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }
        }
    }
}
