import qs
import qs.services
import qs.components
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

BaseExpandPopup {
    id: root

    ipcTarget: "keybinds"
    showSearch: true
    placeholder: "Search keybinds..."

    implicitWidth: 460
    implicitHeight: 440

    property var allBinds: []

    readonly property var keyLabels: ({
        "RETURN": "Enter", "Tab": "Tab",
        "left": "←", "right": "→", "up": "↑", "down": "↓",
        "PERIOD": ".", "COMMA": ",", "slash": "/", "minus": "-", "equal": "=",
        "PRINT": "Print Screen",
        "mouse:272": "Left Click", "mouse:273": "Right Click",
        "mouse_down": "Scroll Down", "mouse_up": "Scroll Up",
        "switch:on:Lid Switch": "Lid Close", "switch:off:Lid Switch": "Lid Open",
        "XF86AudioRaiseVolume": "Volume Up", "XF86AudioLowerVolume": "Volume Down",
        "XF86AudioMute": "Mute", "XF86AudioMicMute": "Mic Mute",
        "XF86AudioPlay": "Play/Pause", "XF86AudioNext": "Next Track", "XF86AudioPrev": "Prev Track",
        "XF86MonBrightnessUp": "Brightness Up", "XF86MonBrightnessDown": "Brightness Down",
    })

    function prettyKey(k) {
        return root.keyLabels[k] ?? k
    }

    function modParts(mask) {
        const parts = []
        if (mask & 64) parts.push("SUPER")
        if (mask & 4) parts.push("CTRL")
        if (mask & 8) parts.push("ALT")
        if (mask & 1) parts.push("SHIFT")
        return parts
    }

    function buildEntry(b) {
        const raw = b.description ?? ""
        const sep = raw.indexOf(": ")
        const section = sep >= 0 ? raw.slice(0, sep) : "Other"
        let desc = sep >= 0 ? raw.slice(sep + 2) : raw

        let keyLabel
        if (b.key === "") {
            const m = desc.match(/\(([^)]+)\)\s*$/)
            keyLabel = m ? m[1] : "?"
            if (m) desc = desc.slice(0, m.index).trim()
        } else {
            keyLabel = root.prettyKey(b.key)
        }

        const combo = [...root.modParts(b.modmask), keyLabel].join(" + ")
        return { section: section, combo: combo, desc: desc }
    }

    Process {
        id: bindsProc
        command: ["hyprctl", "binds", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const arr = JSON.parse(text)
                    root.allBinds = arr
                        .filter(b => b.has_description)
                        .map(b => root.buildEntry(b))
                } catch (e) {
                    root.allBinds = []
                }
            }
        }
    }
    function refresh() { bindsProc.running = true }
    Component.onCompleted: root.refresh()
    onOpened: root.refresh()

    readonly property var filteredBinds: {
        const q = root.searchText.trim().toLowerCase()
        if (q === "") return root.allBinds
        return root.allBinds.filter(b =>
            b.combo.toLowerCase().includes(q)
            || b.desc.toLowerCase().includes(q)
            || b.section.toLowerCase().includes(q))
    }

    minIndex: 0
    maxIndex: Math.max(0, root.filteredBinds.length - 1)
    onSearchEdited: root.selectedIndex = 0

    ListView {
        anchors.fill: parent
        clip: true
        model: root.filteredBinds
        currentIndex: root.selectedIndex
        spacing: 2

        section.property: "section"
        section.delegate: Text {
            width: ListView.view.width
            topPadding: 10
            bottomPadding: 4
            text: section
            color: Theme.hexToRgba(Theme.foreground, 0.4)
            font.pixelSize: 10
            font.bold: true
        }

        Text {
            anchors.centerIn: parent
            visible: parent.count === 0
            text: "No matching keybinds"
            color: Theme.hexToRgba(Theme.foreground, 0.4)
            font.pixelSize: 12
        }

        highlight: Rectangle {
            radius: 8
            color: Theme.hexToRgba(Theme.color5, 0.18)
            border.color: Theme.hexToRgba(Theme.color5, 0.5)
            border.width: 1
        }
        highlightFollowsCurrentItem: true
        highlightMoveDuration: 100

        delegate: RowLayout {
            required property var modelData
            width: ListView.view.width
            height: 32
            spacing: 12

            Text {
                Layout.preferredWidth: 190
                text: modelData.combo
                color: Theme.foreground
                font.pixelSize: 11
                font.family: "Departure Mono"
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: modelData.desc
                color: Theme.hexToRgba(Theme.foreground, 0.6)
                font.pixelSize: 11
                elide: Text.ElideRight
            }
        }
    }
}
