pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property int minTemperature: 2500
    readonly property int maxTemperature: 6500

    readonly property int step: 50

    property bool enabled: false
    readonly property alias temperature: settings.temperature

    FileView {
        id: settingsFile
        path: Quickshell.dataPath("nightlight.json")
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        JsonAdapter {
            id: settings
            property int temperature: 5000
        }
    }

    Process {
        id: checkProc
        command: ["pgrep", "-x", "hyprsunset"]
        stdout: StdioCollector {
            onStreamFinished: root.enabled = text.trim() !== ""
        }
    }

    function refresh() { checkProc.running = true }

    function apply() {
        Quickshell.execDetached(["hyprsunset", "-t", String(root.temperature)])
    }

    function setEnabled(on) {
        if (on) {
            Quickshell.execDetached(["pkill", "-x", "hyprsunset"])
            restartTimer.restart()
        } else {
            Quickshell.execDetached(["pkill", "-x", "hyprsunset"])
        }
        root.enabled = on
        confirmTimer.restart()
    }

    function toggle() { root.setEnabled(!root.enabled) }

    function setTemperature(kelvin) {
        const snapped = Math.round(kelvin / root.step) * root.step
        const k = Math.max(root.minTemperature,
                  Math.min(root.maxTemperature, snapped))

        if (k === settings.temperature) return

        settings.temperature = k
        if (root.enabled) {
            Quickshell.execDetached(["pkill", "-x", "hyprsunset"])
            restartTimer.restart()
        }
    }

    Timer {
        id: restartTimer
        interval: 120
        onTriggered: root.apply()
    }

    Timer {
        id: confirmTimer
        interval: 600
        onTriggered: root.refresh()
    }

    Component.onCompleted: root.refresh()
}
