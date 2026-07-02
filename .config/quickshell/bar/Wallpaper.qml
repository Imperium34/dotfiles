import qs
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: root
    visible: false

    property string homeDir: ""

    Process {
        id: homeResolver
        command: ["bash", "-c", "echo $HOME"]
        running: true
        stdout: StdioCollector {
            id: homeCollector
            onStreamFinished: {
                const t = homeCollector.text
                if (!t) return
                root.homeDir = t.trim()
                currentWallpaperReader.running = true
            }
        }
    }

    anchors.top: true
    anchors.left: true
    anchors.right: true
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    implicitHeight: 152
    color: "transparent"

    property bool animIn: false

    function open() {
        visible = true
        animIn = true
        wallpaperScanner.running = true
    }

    function close() {
        animIn = false
        closeTimer.start()
    }

    function toggle() {
        if (animIn) close()
        else open()
    }

    Timer {
        id: closeTimer
        interval: 200
        onTriggered: root.visible = false
    }

    IpcHandler {
        target: "wallpaper"
        function toggle() { root.toggle() }
    }

    property var wallpapers: []
    property string currentWallpaper: ""

    Process {
        id: wallpaperScanner
        command: ["bash", "-c", "ls " + root.homeDir + "/Pictures/wallpapers/ | sort"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text) return
                root.wallpapers = text.trim().split("\n")
                    .filter(f => f.match(/\.(jpg|jpeg|png|webp|gif)$/i))
            }
        }
    }

    Process {
        id: currentWallpaperReader
        command: ["bash", "-c", "readlink -f " + root.homeDir + "/Pictures/current.png 2>/dev/null || echo ''"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text) return
                root.currentWallpaper = text.trim()
            }
        }
    }

    Process {
        id: awwwProcess
        command: []
    }

    Process {
        id: updateColors
        command: []
    }

    function applyWallpaper(filename) {
        const path = root.homeDir + "/Pictures/wallpapers/" + filename

        awwwProcess.command = ["awww", "img", path,
            "--transition-type", "fade", "--transition-duration", "1"]
        awwwProcess.running = true

        updateColors.command = ["bash", "-c",
            root.homeDir + "/.config/hypr/scripts/update-colors.sh " + path]
        updateColors.running = true

        root.currentWallpaper = path
        close()
    }

    Rectangle {
        id: bg
        anchors.fill: parent
        color: Theme.hexToRgba(Theme.background, 0.92)
        border.color: Theme.hexToRgba(Theme.foreground, 0.08)
        border.width: 1

        transform: Translate {
            y: root.animIn ? 0 : -root.height
            Behavior on y {
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }
        }

        opacity: root.animIn ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }

        ListView {
            id: thumbList
            anchors {
                fill: parent
                margins: 8
            }
            orientation: ListView.Horizontal
            spacing: 8
            clip: true
            model: root.wallpapers

            flickDeceleration: 3000
            maximumFlickVelocity: 4000

            Keys.onEscapePressed: root.close()
            Keys.onReturnPressed: {
                if (currentIndex >= 0 && currentIndex < root.wallpapers.length) {
                    root.applyWallpaper(root.wallpapers[currentIndex])
                }
            }

            highlight: Rectangle {
                width: 200
                height: thumbList.height
                radius: 10
                color: "transparent"
                border.color: Theme.hexToRgba(Theme.color5, 0.9)
                border.width: 2
                z: 2
            }
            highlightFollowsCurrentItem: true
            highlightMoveDuration: 150
            focus: true

            delegate: Item {
                width: 200
                height: thumbList.height
                readonly property string filename: modelData
                readonly property string fullPath: root.homeDir + "/Pictures/wallpapers/" + filename

                Rectangle {
                    anchors.fill: parent
                    radius: 10
                    color: "transparent"
                    border.color: Theme.hexToRgba(Theme.color5, 0.8)
                    border.width: 2
                    visible: root.currentWallpaper.endsWith(filename)
                }

                Image {
                    anchors.fill: parent
                    anchors.margins: root.currentWallpaper.endsWith(filename) ? 3 : 0
                    source: "file://" + root.homeDir + "/Pictures/wallpapers/" + filename
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true

                    Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                        radius: 8
                        Rectangle {
                            anchors.fill: parent
                            radius: 8
                            color: Theme.hexToRgba(Theme.background, 0.2)
                            visible: !root.currentWallpaper.endsWith(filename)
                        }
                    }
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 24
                    radius: 8
                    color: Theme.hexToRgba(Theme.background, 0.7)

                    Text {
                        anchors.centerIn: parent
                        width: parent.width - 8
                        text: filename.replace(/\.[^.]+$/, "")
                        color: Theme.foreground
                        font.pixelSize: 10
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                HoverHandler { id: thumbHover }

                Rectangle {
                    anchors.fill: parent
                    radius: 10
                    color: thumbHover.hovered
                        ? Theme.hexToRgba(Theme.foreground, 0.08)
                        : "transparent"
                    Behavior on color {
                        ColorAnimation { duration: 100 }
                    }
                }

                TapHandler {
                    onTapped: root.applyWallpaper(filename)
                }
            }
        }
    }
}
