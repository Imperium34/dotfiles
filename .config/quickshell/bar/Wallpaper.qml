import qs
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

PopupWindow {
    id: root
    visible: false
    color: "transparent"

    property var barWindow: null
    property string homeDir: ""
    property real originX: 0
    property real originWidth: 200

    implicitWidth: barWindow ? barWindow.width * 0.50 : 1200
    implicitHeight: 190

    anchor {
        window: barWindow
        rect: Qt.rect(
            Math.max(8, Math.min(
                originX - implicitWidth / 2,
                (barWindow?.width ?? 1920) - implicitWidth - 8
            )),
            0,
            0, 0
        )
    }

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
        if (root.homeDir) {
            wallpaperScanner.running = true
        }
        focusGrab.active = true
    }

    onHomeDirChanged: if (visible) wallpaperScanner.running = true

    function close() {
        animIn = false
        focusGrab.active = false
        closeTimer.start()
    }

    function toggle() {
        if (animIn) close()
        else open()
    }

    HyprlandFocusGrab {
        id: focusGrab
        windows: [root]
        onCleared: root.close()
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

    // ---- theme presets ----
    property bool showingThemeTab: false
    readonly property var themePresets: ["vibrant", "muted", "pastel", "dark", "mono"]
    property int presetGenIndex: -1
    property string previewedWallpaper: ""

    onShowingThemeTabChanged: {
        if (showingThemeTab && root.previewedWallpaper !== root.currentWallpaper) {
            root.previewedWallpaper = root.currentWallpaper
            root.presetGenIndex = 0
            presetGenProc.running = true
        }
    }

    Process {
        id: presetGenProc
        command: (root.presetGenIndex >= 0 && root.presetGenIndex < root.themePresets.length) ? [
            root.homeDir + "/.config/quickshell/scripts/preview-theme.sh",
            root.previewedWallpaper,
            root.homeDir + "/.config/wallust/presets/" + root.themePresets[root.presetGenIndex] + ".toml",
            "/tmp/wallust-preview-" + root.themePresets[root.presetGenIndex] + ".json"
        ] : []
        onExited: {
            root.presetGenIndex++
            if (root.presetGenIndex < root.themePresets.length) {
                running = true
            } else {
                root.presetGenIndex = -1
            }
        }
    }

    Process {
        id: applyThemeProc
        command: []
    }

    function applyPreset(name) {
        applyThemeProc.command = [
            root.homeDir + "/.config/quickshell/scripts/apply-theme.sh",
            root.currentWallpaper,
            root.homeDir + "/.config/wallust/presets/" + name + ".toml"
        ]
        applyThemeProc.running = true
        close()
    }

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
        radius: 20
        antialiasing: true
        transformOrigin: Item.Top
        scale: root.animIn ? 1 : (root.originWidth / (barWindow ? barWindow.width * 0.65 : 1200))
        opacity: root.animIn ? 1 : 0
        Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

        color: Theme.hexToRgba(Theme.background, Theme.surfaceAlpha(0.92))
        border.color: Theme.hexToRgba(Theme.foreground, 0.08)
        border.width: 1

        RowLayout {
            id: tabRow
            anchors { top: parent.top; horizontalCenter: parent.horizontalCenter; topMargin: 8 }
            height: 26
            spacing: 6

            Rectangle {
                Layout.preferredWidth: 90
                Layout.fillHeight: true
                radius: 8
                color: !root.showingThemeTab ? Theme.hexToRgba(Theme.color5, 0.25) : "transparent"
                Behavior on color { ColorAnimation { duration: 120 } }
                Text {
                    anchors.centerIn: parent
                    text: "Wallpaper"
                    color: Theme.foreground
                    font.pixelSize: 11
                    font.bold: !root.showingThemeTab
                }
                TapHandler { onTapped: root.showingThemeTab = false }
            }
            Rectangle {
                Layout.preferredWidth: 90
                Layout.fillHeight: true
                radius: 8
                color: root.showingThemeTab ? Theme.hexToRgba(Theme.color5, 0.25) : "transparent"
                Behavior on color { ColorAnimation { duration: 120 } }
                Text {
                    anchors.centerIn: parent
                    text: "Theme"
                    color: Theme.foreground
                    font.pixelSize: 11
                    font.bold: root.showingThemeTab
                }
                TapHandler { onTapped: root.showingThemeTab = true }
            }
        }

        ListView {
            id: thumbList
            anchors {
                top: tabRow.bottom
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                margins: 8
                topMargin: 6
            }
            visible: !root.showingThemeTab
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
            Keys.onTabPressed: {
                root.showingThemeTab = !root.showingThemeTab
                event.accepted = true
            }
            Keys.onPressed: {
                if (event.key === Qt.Key_Space) {
                    root.showingThemeTab = !root.showingThemeTab
                    event.accepted = true
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
            focus: !root.showingThemeTab

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

        ListView {
            id: presetList
            anchors {
                top: tabRow.bottom
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                margins: 8
                topMargin: 6
            }
            visible: root.showingThemeTab
            orientation: ListView.Horizontal
            spacing: 8
            clip: true
            model: root.themePresets
            focus: root.showingThemeTab

            Keys.onEscapePressed: root.close()
            Keys.onReturnPressed: {
                if (currentIndex >= 0 && currentIndex < root.themePresets.length) {
                    root.applyPreset(root.themePresets[currentIndex])
                }
            }
            Keys.onTabPressed: {
                root.showingThemeTab = !root.showingThemeTab
                event.accepted = true
            }
            Keys.onPressed: {
                if (event.key === Qt.Key_Space) {
                    root.showingThemeTab = !root.showingThemeTab
                    event.accepted = true
                }
            }

            delegate: Item {
                id: presetThumb
                width: 160
                height: presetList.height
                readonly property string presetName: modelData
                readonly property bool isGenerating: root.presetGenIndex >= 0
                    && root.themePresets[root.presetGenIndex] === presetName

                FileView {
                    id: previewFile
                    path: "/tmp/wallust-preview-" + presetThumb.presetName + ".json"
                    watchChanges: true
                    onFileChanged: reload()
                    JsonAdapter {
                        id: swatchAdapter
                        property string background: "#000000"
                        property string foreground: "#ffffff"
                        property string color0: "#000000"
                        property string color1: "#000000"
                        property string color2: "#000000"
                        property string color3: "#000000"
                        property string color4: "#000000"
                        property string color5: "#000000"
                        property string color6: "#000000"
                        property string color7: "#000000"
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 10
                    color: Theme.hexToRgba(Theme.foreground, 0.05)
                    border.color: presetList.currentIndex === index
                        ? Theme.color5 : Theme.hexToRgba(Theme.foreground, 0.1)
                    border.width: presetList.currentIndex === index ? 2 : 1
                    Behavior on border.color { ColorAnimation { duration: 120 } }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        GridLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            columns: 4
                            rowSpacing: 4
                            columnSpacing: 4

                            Repeater {
                                model: [
                                    swatchAdapter.color1, swatchAdapter.color2,
                                    swatchAdapter.color3, swatchAdapter.color4,
                                    swatchAdapter.color5, swatchAdapter.color6,
                                    swatchAdapter.color7, swatchAdapter.background
                                ]
                                delegate: Rectangle {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: 4
                                    color: modelData
                                }
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: presetThumb.presetName
                            color: Theme.foreground
                            font.pixelSize: 11
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: 10
                        color: Theme.hexToRgba(Theme.background, 0.5)
                        visible: presetThumb.isGenerating
                        Text {
                            anchors.centerIn: parent
                            text: "…"
                            color: Theme.foreground
                            font.pixelSize: 18
                        }
                    }
                }

                TapHandler {
                    onTapped: root.applyPreset(presetThumb.presetName)
                }
            }
        }
    }
}
