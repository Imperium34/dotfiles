import Quickshell
import Quickshell.Io
import QtQuick

// Reacts to power-state changes by driving things OUTSIDE Quickshell: shell
// scripts, hyprctl, anything with a side effect.
QtObject {
    id: root

    readonly property string home: Quickshell.env("HOME")

    readonly property int debounceMs: 1500

    readonly property bool heavy: PowerState.heavyEffectsEnabled

    // ── ACTIONS ────────────────────────────────────────────────
    readonly property Process blurProc: Process { command: [] }
    readonly property Process videoProc: Process { command: [] }

    function apply() {
        // Hyprland window blur.
        root.blurProc.command = [
            root.home + "/.config/hypr/scripts/set-blur.sh",
            root.heavy ? "on" : "off"
        ]
        root.blurProc.running = true

        // mpvpaper video wallpaper layer.
        root.videoProc.command = [
            root.home + "/.config/quickshell/scripts/video-wallpaper.sh",
            root.heavy ? "resume" : "stop"
        ]
        root.videoProc.running = true
    }

    readonly property Timer debounce: Timer {
        interval: root.debounceMs
        onTriggered: root.apply()
    }

    readonly property Connections watcher: Connections {
        target: PowerState
        function onHeavyEffectsEnabledChanged() { root.debounce.restart() }
    }

    Component.onCompleted: root.debounce.restart()
}
