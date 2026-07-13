import qs
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: root
    visible: false
    WlrLayershell.namespace: "wallpaper"

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

    property int applyingIndex: -1
    property string pendingFilename: ""

    property string transitionType: "grow"
    property string transitionPos: "center"
    property real transitionDuration: 0.7
    property int transitionFps: 144

    function open() {
        visible = true
        animIn = true
        applyingIndex = -1
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

    function applyWallpaper(filename, index) {
        if (root.applyingIndex !== -1) return
        root.applyingIndex = index
        root.pendingFilename = filename
        applyTimer.start()
    }

    Timer {
        id: applyTimer
        interval: 220
        onTriggered: root.commitWallpaper()
    }

    function commitWallpaper() {
        const path = root.homeDir + "/Pictures/wallpapers/" + root.pendingFilename

        awwwProcess.command = ["awww", "img", path,
            "--transition-type", root.transitionType,
            "--transition-pos", root.transitionPos,
            "--transition-duration", String(root.transitionDuration),
            "--transition-fps", String(root.transitionFps)]
        awwwProcess.running = true

        updateColors.command = [root.homeDir + "/.config/quickshell/scripts/update-colors.sh", path]
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
                    root.applyWallpaper(root.wallpapers[currentIndex], currentIndex)
                }
            }

            highlight: Item {
                z: 2
                width: 200
                height: thumbList.height

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -2
                    radius: 12
                    color: "transparent"
                    border.color: Theme.hexToRgba(Theme.color5, 0.3)
                    border.width: 4
                }
                Rectangle {
                    anchors.fill: parent
                    radius: 10
                    color: "transparent"
                    border.color: Theme.color5
                    border.width: 2
                }
            }
            highlightFollowsCurrentItem: true
            highlightMoveDuration: 120
            focus: true

            delegate: Item {
                id: thumb
                width: 200
                height: thumbList.height
                readonly property string filename: modelData
                readonly property bool isCurrent: root.currentWallpaper.endsWith(filename)
                readonly property bool applying: index === root.applyingIndex

                scale: applying ? 1.05 : 1.0
                Behavior on scale {
                    NumberAnimation { duration: 160; easing.type: Easing.OutBack; easing.overshoot: 1.4 }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 10
                    color: "transparent"
                    border.color: Theme.hexToRgba(Theme.color5, 0.8)
                    border.width: 2
                    visible: thumb.isCurrent
                }

                Image {
                    id: thumbImg
                    anchors.fill: parent
                    anchors.margins: thumb.isCurrent ? 3 : 0
                    source: "file://" + root.homeDir + "/Pictures/wallpapers/" + filename
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: 400
                    asynchronous: true
                    cache: true

                    Rectangle {
                        anchors.fill: parent
                        radius: 8
                        color: Theme.hexToRgba(Theme.background, thumb.isCurrent ? 0 : 0.25)
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }

                Rectangle {
                    id: placeholder
                    anchors.fill: parent
                    radius: 10
                    color: Theme.hexToRgba(Theme.foreground, 0.05)
                    opacity: thumbImg.status === Image.Ready ? 0 : 1
                    visible: opacity > 0
                    Behavior on opacity {
                        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: 10
                        color: Theme.hexToRgba(Theme.foreground, 0.06)
                        SequentialAnimation on opacity {
                            running: placeholder.visible
                            loops: Animation.Infinite
                            NumberAnimation { from: 0.2; to: 0.8; duration: 700; easing.type: Easing.InOutSine }
                            NumberAnimation { from: 0.8; to: 0.2; duration: 700; easing.type: Easing.InOutSine }
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

                Rectangle {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 6
                    width: 20
                    height: 20
                    radius: 10
                    color: Theme.color5
                    visible: thumb.isCurrent

                    Text {
                        anchors.centerIn: parent
                        text: "󰄬"
                        color: Theme.background
                        font.pixelSize: 12
                        font.family: "Symbols Nerd Font"
                    }
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: 44
                    height: 44
                    radius: 22
                    color: Theme.hexToRgba(Theme.color5, 0.9)
                    opacity: thumb.applying ? 1 : 0
                    scale: thumb.applying ? 1 : 0.6
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                    Behavior on scale {
                        NumberAnimation { duration: 200; easing.type: Easing.OutBack; easing.overshoot: 1.6 }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "󰄬"
                        color: Theme.background
                        font.pixelSize: 22
                        font.family: "Symbols Nerd Font"
                    }
                }

                TapHandler {
                    onTapped: root.applyWallpaper(thumb.filename, index)
                }
            }
        }
    }
}
