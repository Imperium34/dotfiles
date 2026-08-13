import qs
import qs.services
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
    readonly property string homeDir: Quickshell.env("HOME") ?? ""
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

    // ---- open/close phase state ----
    readonly property int widthPhaseDuration: Math.round(
        Math.abs(root.implicitWidth - root.originWidth) / ExpandPopupCoordinator.growSpeed * 1000)
    readonly property int heightPhaseDuration: Math.round(
        root.implicitHeight / ExpandPopupCoordinator.growSpeed * 4000)

    property int openPhaseDuration: root.widthPhaseDuration

    ExpandPopupController {
        id: controller
        animEnter: root.heightPhaseDuration
        animExit: root.heightPhaseDuration
        onClosed: {
            ExpandPopupCoordinator.collapse(root)
            widthShrinkTimer.restart()
        }
    }

    // content (tabs/lists) only fades in once the height grow has actually
    // finished, and disappears the instant close() is called
    readonly property bool contentReady: controller.animIn && !growGuard.running
    Timer {
        id: growGuard
        interval: root.heightPhaseDuration
    }
    Connections {
        target: controller
        function onAnimInChanged() {
            if (controller.animIn) growGuard.restart()
        }
    }

    property int applyingIndex: -1
    property string pendingFilename: ""

    function open() {
        widthShrinkTimer.stop()
        visible = true
        applyingIndex = -1
        wallpaperScanner.running = true
        syncPresetSelection()
        focusGrab.active = true
        const startWidth = ExpandPopupCoordinator.expand(root)
        root.openPhaseDuration = Math.round(
            Math.abs(root.implicitWidth - startWidth) / ExpandPopupCoordinator.growSpeed * 1000)
        widthPhaseTimer.restart()
    }

    function close() {
        focusGrab.active = false
        controller.close()
    }

    function toggle() {
        if (root.visible) close()
        else open()
    }

    HyprlandFocusGrab {
        id: focusGrab
        windows: [root]
        onCleared: root.close()
    }

    // ---- phase timers ----
    Timer {
        id: widthPhaseTimer
        interval: root.openPhaseDuration
        onTriggered: controller.open()
    }

    Timer {
        id: widthShrinkTimer
        interval: root.widthPhaseDuration
        onTriggered: {
            root.visible = false
            ExpandPopupCoordinator.notifyClosed(root)
        }
    }
    IpcHandler {
        target: "wallpaper"
        function toggle() { root.toggle() }
    }

    property var thumbPaths: ({})
    property var wallpapers: []
    property string currentWallpaper: ""

    // ---- categories (subfolders under Pictures/wallpapers) ----
    property var categories: []
    property string selectedCategory: "All"
    readonly property var filteredWallpapers: root.selectedCategory === "All"
        ? root.wallpapers
        : root.wallpapers.filter(f => f.split("/")[0] === root.selectedCategory)

    function cycleCategory(step) {
        const list = ["All", ...root.categories]
        if (list.length === 0) return
        const idx = list.indexOf(root.selectedCategory)
        const next = (idx + step + list.length) % list.length
        root.selectedCategory = list[next]
    }

    // ---- theme presets ----
    property bool showingThemeTab: false
    readonly property var themePresets: ["vibrant", "muted", "pastel", "dark", "mono"]
    property string previewedWallpaper: ""
    property bool generatingPresets: false
    property var presetPreviewPaths: ({})
    property var lastPresetByWallpaper: ({})
    readonly property string lastPresetStateFile: root.homeDir + "/.cache/quickshell/last-presets.json"
    readonly property string currentWallpaperStateFile: root.homeDir + "/.cache/quickshell/current-wallpaper"

    function generatePresetsFor(wallpaper) {
        root.previewedWallpaper = wallpaper
        root.generatingPresets = true
        if (generateAllProc.running) {
            generateAllProc.running = false
        }
        generateAllProc.command = [
            root.homeDir + "/.config/quickshell/scripts/generate-presets.sh",
            wallpaper,
            root.homeDir + "/.config/wallust/presets",
            "/tmp",
            ...root.themePresets
        ]
        generateAllProc.running = true
    }

    function syncPresetSelection() {
        const last = root.lastPresetByWallpaper[root.currentWallpaper]
        presetList.currentIndex = last ? root.themePresets.indexOf(last) : -1
    }

    onShowingThemeTabChanged: {
        if (showingThemeTab) {
            root.syncPresetSelection()
            if (root.previewedWallpaper !== root.currentWallpaper) {
                root.generatePresetsFor(root.currentWallpaper)
            }
        }
    }

    Process {
        id: generateAllProc
        command: []
        stdout: StdioCollector {
                onStreamFinished: {
                  const map = {}
                  if (text) {
                      for (const line of text.trim().split("\n")) {
                          const i = line.indexOf(":")
                          if (i > 0) map[line.slice(0, i)] = line.slice(i + 1)
                      }
                  }

                  if (map["#wallpaper"] !== root.previewedWallpaper) return
                  delete map["#wallpaper"]

                  root.presetPreviewPaths = map
                  root.generatingPresets = false
                }
        }
    }

    // ---- last-used preset memory (persisted to disk) ----
    Process {
        id: lastPresetReader
        command: ["bash", "-c", "cat '" + root.lastPresetStateFile + "' 2>/dev/null || echo '{}'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.lastPresetByWallpaper = text ? JSON.parse(text) : {}
                } catch (e) {
                    root.lastPresetByWallpaper = {}
                }
                if (root.visible) root.syncPresetSelection()
            }
        }
    }

    Process {
        id: savePresetChoiceProc
        command: []
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

        const map = Object.assign({}, root.lastPresetByWallpaper)
        map[root.currentWallpaper] = name
        root.lastPresetByWallpaper = map
        savePresetChoiceProc.command = [
            root.homeDir + "/.config/quickshell/scripts/save-last-preset.sh",
            root.currentWallpaper,
            name,
            root.lastPresetStateFile
        ]
        savePresetChoiceProc.running = true

        close()
    }

    Process {
        id: wallpaperScanner
        command: [root.homeDir + "/.config/quickshell/scripts/scan-wallpapers.sh"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text) return
                const files = []
                const thumbs = {}
                for (const line of text.trim().split("\n")) {
                    const i = line.indexOf("\t")
                    if (i <= 0) continue
                    const rel = line.slice(0, i)
                    files.push(rel)
                    thumbs[rel] = line.slice(i + 1)
                }
                root.wallpapers = files
                root.thumbPaths = thumbs
                root.categories = [...new Set(files.map(f => f.split("/")[0]))].sort()
                if (root.selectedCategory !== "All" && !root.categories.includes(root.selectedCategory)) {
                    root.selectedCategory = "All"
                }
            }
        }
    }

    Process {
        id: currentWallpaperReader
        command: ["bash", "-c",
            "cat '" + root.currentWallpaperStateFile + "' 2>/dev/null || true"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim()
                if (p) root.currentWallpaper = p
            }
        }
    }

    Process {
        id: applyWallpaperProc
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

        applyWallpaperProc.command = [
            root.homeDir + "/.config/quickshell/scripts/apply-wallpaper.sh",
            path
        ]
        applyWallpaperProc.running = true

        root.currentWallpaper = path
        root.generatePresetsFor(path)
        close()
    }

    // ---- card: width is already fixed (matches the bar's target width),
    // only height grows/shrinks, matching BaseExpandPopup's phase style ----
    Rectangle {
        id: bg
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: controller.animIn ? root.implicitHeight : 0
        clip: true
        radius: Math.min(20, height / 2)
        antialiasing: true

        color: Theme.hexToRgba(Theme.background, Theme.surfaceAlpha(0.92))
        border.color: Theme.hexToRgba(Theme.foreground, 0.08)
        border.width: 1

        Behavior on height {
            NumberAnimation { duration: root.heightPhaseDuration; easing.type: Easing.OutCubic }
        }

        Item {
            id: contentArea
            anchors.fill: parent
            opacity: root.contentReady ? 1 : 0
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
            }

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

            Item {
                id: categoryRowContainer
                anchors { top: tabRow.bottom; left: parent.left; right: parent.right; margins: 8; topMargin: 6 }
                height: 22
                visible: !root.showingThemeTab && root.categories.length > 0

                ListView {
                    id: categoryRow
                    anchors.fill: parent
                    orientation: ListView.Horizontal
                    spacing: 6
                    clip: true
                    model: ["All", ...root.categories]

                    delegate: Rectangle {
                        readonly property bool isSelected: root.selectedCategory === modelData
                        width: chipLabel.implicitWidth + 16
                        height: categoryRow.height
                        radius: 6
                        color: isSelected ? Theme.hexToRgba(Theme.color5, 0.3) : Theme.hexToRgba(Theme.foreground, 0.06)
                        border.color: isSelected ? Theme.color5 : "transparent"
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            id: chipLabel
                            anchors.centerIn: parent
                            text: modelData
                            color: Theme.foreground
                            font.pixelSize: 10
                            font.bold: isSelected
                        }
                        TapHandler { onTapped: root.selectedCategory = modelData }
                    }
                }

                // Edge fades hint that there's more to scroll when chips overflow the row
                Rectangle {
                    anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                    width: 18
                    visible: categoryRow.contentWidth > categoryRow.width && !categoryRow.atXBeginning
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: Theme.hexToRgba(Theme.background, 0.92) }
                        GradientStop { position: 1.0; color: Theme.hexToRgba(Theme.background, 0.0) }
                    }
                }
                Rectangle {
                    anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
                    width: 18
                    visible: categoryRow.contentWidth > categoryRow.width && !categoryRow.atXEnd
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: Theme.hexToRgba(Theme.background, 0.0) }
                        GradientStop { position: 1.0; color: Theme.hexToRgba(Theme.background, 0.92) }
                    }
                }
            }

            ListView {
                id: thumbList
                anchors {
                    top: root.categories.length > 0 ? categoryRowContainer.bottom : tabRow.bottom
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
                model: root.filteredWallpapers

                flickDeceleration: 3000
                maximumFlickVelocity: 4000

                Text {
                    anchors.centerIn: parent
                    text: "Loading wallpapers…"
                    color: Theme.hexToRgba(Theme.foreground, 0.5)
                    font.pixelSize: 12
                    visible: wallpaperScanner.running && root.wallpapers.length === 0
                }

                Keys.onEscapePressed: root.close()
                Keys.onReturnPressed: {
                    if (currentIndex >= 0 && currentIndex < root.filteredWallpapers.length) {
                        root.applyWallpaper(root.filteredWallpapers[currentIndex], currentIndex)
                    }
                }
                Keys.onTabPressed: (event) => {
                    root.showingThemeTab = !root.showingThemeTab
                    event.accepted = true
                }
                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Space) {
                        root.cycleCategory(event.modifiers & Qt.ShiftModifier ? -1 : 1)
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
                        source: "file://" + (root.thumbPaths[filename]
                            ?? (root.homeDir + "/Pictures/wallpapers/" + filename))
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
                            text: filename.split("/").pop().replace(/\.[^.]+$/, "")
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
                Keys.onTabPressed: (event) => {
                    root.showingThemeTab = !root.showingThemeTab
                    event.accepted = true
                }
                Keys.onPressed: (event) => {
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
                    readonly property bool isGenerating: root.generatingPresets

                    FileView {
                        id: previewFile
                        path: root.presetPreviewPaths[presetThumb.presetName] ?? ""
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
}
