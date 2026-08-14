import qs
import qs.services
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: osdWindow

    screen: BarRegistry.focusedBar ? BarRegistry.focusedBar.screen : null

    anchors {
        bottom: true
        left: true
        right: true
    }

    mask: Region {
        item: osdWindow.animIn ? osdContent : null
    }

    implicitHeight: 80
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    property string mode: "volume"
    property bool animIn: false

    property int brightCurrent: 0
    property int brightMax: 1
    readonly property real brightness: brightMax > 0 ? brightCurrent / brightMax : 0

    readonly property int cardWidth: 280
    readonly property int collapsedWidth: 120

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var audio: sink ? sink.audio : null
    readonly property real volume: audio ? audio.volume : 0
    readonly property bool muted: audio ? audio.muted : false

    Timer {
        id: dismissTimer
        interval: 1500
        onTriggered: osdWindow.animIn = false
    }

    function show(newMode: string): void {
        osdWindow.mode = newMode
        osdWindow.animIn = true
        dismissTimer.restart()
    }

    // Brightness processes
    Process {
        id: brightGet
        command: ["/usr/bin/brightnessctl", "get"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: osdWindow.brightCurrent = parseInt(text.trim()) || 0
        }
    }

    Process {
        id: brightMaxProc
        command: ["/usr/bin/brightnessctl", "max"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: osdWindow.brightMax = parseInt(text.trim()) || 1
        }
    }

    Process {
        id: brightUp
        command: ["/usr/bin/brightnessctl", "-q", "set", "5%+"]
        onRunningChanged: if (!running) brightGet.running = true
    }

    Process {
        id: brightDown
        command: ["/usr/bin/brightnessctl", "-q", "set", "5%-"]
        onRunningChanged: if (!running) brightGet.running = true
    }

    IpcHandler {
        target: "osd"

        function volumeUp(): void {
            if (osdWindow.audio)
                osdWindow.audio.volume = Math.min(1, Math.round((osdWindow.audio.volume + 0.05) * 100) / 100)
            osdWindow.show("volume")
        }

        function volumeDown(): void {
            if (osdWindow.audio)
                osdWindow.audio.volume = Math.max(0, Math.round((osdWindow.audio.volume - 0.05) * 100) / 100)
            osdWindow.show("volume")
        }

        function volumeMute(): void {
            if (osdWindow.audio) osdWindow.audio.muted = !osdWindow.audio.muted
            osdWindow.show("volume")
        }

        function brightnessUp(): void {
            brightUp.running = true
            osdWindow.show("brightness")
        }

        function brightnessDown(): void {
            brightDown.running = true
            osdWindow.show("brightness")
        }
    }

    Item {
        id: osdContent
        anchors.centerIn: parent
        width: osdWindow.cardWidth
        height: 56

        Rectangle {
            id: card
            anchors.centerIn: parent
            height: parent.height
            radius: height / 2
            color: Theme.hexToRgba(Theme.background, Theme.surfaceAlpha(0.92))
            border.color: Theme.hexToRgba(Theme.foreground, 0.1)
            border.width: 1
            clip: true

            width: osdWindow.animIn ? osdWindow.cardWidth : osdWindow.collapsedWidth
            opacity: osdWindow.animIn ? 1 : 0

            Behavior on width {
                NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
            }
            Behavior on opacity {
                NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
            }

            RowLayout {
                width: osdWindow.cardWidth - 40
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 12

                opacity: osdWindow.animIn ? 1 : 0
                Behavior on opacity {
                    NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                }

                Text {
                    text: {
                        if (osdWindow.mode === "brightness") return "󰖨"
                        if (osdWindow.muted || osdWindow.volume === 0) return "󰝟"
                        if (osdWindow.volume < 0.34) return "󰕿"
                        if (osdWindow.volume < 0.67) return "󰖀"
                        return "󰕾"
                    }
                    color: Theme.foreground
                    font.pixelSize: 20
                    font.family: "Symbols Nerd Font"
                }

                Item {
                    Layout.fillWidth: true
                    height: 20

                    Rectangle {
                        anchors {
                            left: parent.left
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                        }
                        height: 6
                        radius: 3
                        color: Theme.hexToRgba(Theme.foreground, 0.15)

                        Rectangle {
                            width: parent.width * (osdWindow.mode === "brightness"
                                ? osdWindow.brightness
                                : (osdWindow.muted ? 0 : osdWindow.volume))
                            height: parent.height
                            radius: 3
                            color: osdWindow.mode === "brightness" ? Theme.color3 : Theme.color5
                            Behavior on width {
                                NumberAnimation { duration: 100 }
                            }
                        }
                    }
                }

                Text {
                    text: osdWindow.mode === "brightness"
                        ? Math.round(osdWindow.brightness * 100) + "%"
                        : (osdWindow.muted ? "Muted" : Math.round(osdWindow.volume * 100) + "%")
                    color: Theme.foreground
                    font.pixelSize: 13
                    Layout.minimumWidth: 42
                    horizontalAlignment: Text.AlignRight
                }
            }
        }
    }
}
