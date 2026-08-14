pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Extracted from OSD.qml so anything that wants brightness reads the same
// state. Previously the OSD owned the only copy of these processes, so a
// second consumer meant a second set of brightnessctl invocations that
// couldn't see each other's changes.
Singleton {
    id: root

    property int current: 0
    property int max: 1

    readonly property real fraction: max > 0 ? current / max : 0

    readonly property bool available: max > 1

    Process {
        id: getProc
        command: ["/usr/bin/brightnessctl", "get"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.current = parseInt(text.trim()) || 0
        }
    }

    Process {
        id: maxProc
        command: ["/usr/bin/brightnessctl", "max"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.max = parseInt(text.trim()) || 1
        }
    }

    Process {
        id: setProc
        command: []
        onRunningChanged: if (!running) getProc.running = true
    }

    function refresh() { getProc.running = true }

    function up() {
        setProc.command = ["/usr/bin/brightnessctl", "-q", "set", "5%+"]
        setProc.running = true
    }

    function down() {
        setProc.command = ["/usr/bin/brightnessctl", "-q", "set", "5%-"]
        setProc.running = true
    }

    function setPercent(percent) {
        const v = Math.max(1, Math.min(100, Math.round(percent)))
        setProc.command = ["/usr/bin/brightnessctl", "-q", "set", v + "%"]
        setProc.running = true
    }
}
