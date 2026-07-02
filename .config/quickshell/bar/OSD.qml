import qs
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: osdWindow

    anchors {
        bottom: true
        left: true
        right: true
    }

    mask: Region {
        item: animIn ? osdContent : null
    }

    implicitHeight: 80
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    property string mode: "volume"  // "volume" or "brightness"
    property bool animIn: false

    property int brightCurrent: 0
    property int brightMax: 1
    readonly property real brightness: brightMax > 0 ? brightCurrent / brightMax : 0

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
        onTriggered: animIn = false
    }

    function show(newMode: string): void {
        mode = newMode
        animIn = true
        dismissTimer.restart()
    }

    // Brightness processes
    Process {
        id: brightGet
        command: ["/usr/bin/brightnessctl", "get"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: brightCurrent = parseInt(text.trim()) || 0
        }
    }

    Process {
        id: brightMaxProc
        command: ["/usr/bin/brightnessctl", "max"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: brightMax = parseInt(text.trim()) || 1
        }
    }

    Process {
        id: brightUp
        command: ["/usr/bin/brightnessctl", "-q", "set", "5%+"]
        onRunningChanged: if (!running) { brightGet.running = true }
    }

    Process {
        id: brightDown
        command: ["/usr/bin/brightnessctl", "-q", "set", "5%-"]
        onRunningChanged: if (!running) { brightGet.running = true }
    }

    IpcHandler {
        target: "osd"

        function volumeUp(): void {
            if (audio) audio.volume = Math.min(1, Math.round((audio.volume + 0.05) * 100) / 100)
            osdWindow.show("volume")
        }

        function volumeDown(): void {
            if (audio) audio.volume = Math.max(0, Math.round((audio.volume - 0.05) * 100) / 100)
            osdWindow.show("volume")
        }

        function volumeMute(): void {
            if (audio) audio.muted = !audio.muted
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
        anchors.centerIn: parent
        width: 280
        height: 56

        Rectangle {
            id: card
            anchors.fill: parent
            radius: 28
            color: Theme.hexToRgba(Theme.background, 0.92)
            border.color: Theme.hexToRgba(Theme.foreground, 0.1)
            border.width: 1

            opacity: animIn ? 1 : 0
            scale: animIn ? 1 : 0.95

            Behavior on opacity {
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }
            Behavior on scale {
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }

            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: 20
                    rightMargin: 20
                }
                spacing: 12

                Text {
                    text: {
                        if (mode === "brightness") return "󰖨"
                        if (muted || volume === 0) return "󰝟"
                        if (volume < 0.34) return ""
                        if (volume < 0.67) return ""
                        return ""
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
                            width: parent.width * (mode === "brightness" ? brightness : (muted ? 0 : volume))
                            height: parent.height
                            radius: 3
                            color: mode === "brightness" ? Theme.color3 : Theme.color5
                            Behavior on width {
                                NumberAnimation { duration: 100 }
                            }
                        }
                    }
                }

                Text {
                    text: mode === "brightness"
                        ? Math.round(brightness * 100) + "%"
                        : (muted ? "Muted" : Math.round(volume * 100) + "%")
                    color: Theme.foreground
                    font.pixelSize: 13
                    Layout.minimumWidth: 42
                    horizontalAlignment: Text.AlignRight
                }
            }
        }
    }
}
