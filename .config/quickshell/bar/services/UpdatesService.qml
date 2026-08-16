pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // repo updates via `checkupdates` (pacman-contrib) sync a throwaway
    // copy of the pacman db, so no root/password prompt is needed.
    // AUR updates via `paru -Qua` hit the AUR RPC directly, same deal.
    property var repoUpdates: []
    property var aurUpdates: []
    readonly property var packages: [...root.repoUpdates, ...root.aurUpdates]
    readonly property int pendingCount: root.packages.length

    readonly property bool checking: repoCheck.running || aurCheck.running
    property bool updating: false

    function parseUpdateLines(text, source) {
        if (!text) return []
        return text.trim().split("\n").filter(l => l.trim() !== "").map(line => {
            const parts = line.trim().split(/\s+/)
            return {
                name: parts[0] ?? line,
                oldVersion: parts[1] ?? "",
                newVersion: parts[3] ?? "",
                source: source
            }
        })
    }

    Process {
        id: repoCheck
        command: ["checkupdates"]
        stdout: StdioCollector {
            onStreamFinished: root.repoUpdates = root.parseUpdateLines(text, "repo")
        }
    }

    Process {
        id: aurCheck
        command: ["paru", "-Qua"]
        stdout: StdioCollector {
            onStreamFinished: root.aurUpdates = root.parseUpdateLines(text, "aur")
        }
    }

    function refresh() {
        repoCheck.running = true
        aurCheck.running = true
    }

    Process {
        id: updateProc
        command: ["alacritty", "-e", "paru"]
        onRunningChanged: root.updating = running
        onExited: root.refresh()
    }

    function runUpdate() {
        if (root.updating) return
        updateProc.running = true
    }

    Timer {
        interval: 30 * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: false
        onTriggered: root.refresh()
    }

    Component.onCompleted: root.refresh()
}
