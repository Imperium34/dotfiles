pragma Singleton

import qs.services
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string phaseIdle: "idle"
    readonly property string phaseFocus: "focus"
    readonly property string phaseBreak: "break"

    property string phase: root.phaseIdle
    property bool running: false
    property int remainingSeconds: 0
    property int cyclesCompleted: 0

    readonly property bool isLongBreak: root.cyclesCompleted > 0
        && root.cyclesCompleted % settings.cyclesUntilLongBreak === 0

    readonly property int totalSeconds: {
        if (root.phase === root.phaseBreak)
            return (root.isLongBreak ? settings.longBreakMinutes : settings.breakMinutes) * 60
        return settings.focusMinutes * 60
    }
    readonly property real progress: root.totalSeconds > 0
        ? 1 - (root.remainingSeconds / root.totalSeconds) : 0

    readonly property string remainingLabel: {
        const m = Math.floor(root.remainingSeconds / 60)
        const s = root.remainingSeconds % 60
        return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s
    }

    // ---- settings (persisted) ----
    FileView {
        id: settingsFile
        path: Quickshell.dataPath("pomodoro.json")
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        JsonAdapter {
            id: settings
            property int focusMinutes: 25
            property int breakMinutes: 5
            property int longBreakMinutes: 15
            property int cyclesUntilLongBreak: 4
        }
    }
    readonly property alias focusMinutes: settings.focusMinutes
    readonly property alias breakMinutes: settings.breakMinutes
    readonly property alias longBreakMinutes: settings.longBreakMinutes

    // durations are only adjustable between sessions, not mid-countdown
    function setFocusMinutes(m) {
        if (root.phase !== root.phaseIdle) return
        settings.focusMinutes = Math.max(5, Math.round(m))
    }
    function setBreakMinutes(m) {
        if (root.phase !== root.phaseIdle) return
        settings.breakMinutes = Math.max(1, Math.round(m))
    }

    // ---- controls ----
    function start() {
        if (root.phase === root.phaseIdle) {
            root.phase = root.phaseFocus
            root.remainingSeconds = settings.focusMinutes * 60
        }
        root.running = true
        if (root.phase === root.phaseFocus) IdleInhibit.inhibit("pomodoro")
        tickTimer.restart()
    }

    function pause() {
        root.running = false
        tickTimer.stop()
        IdleInhibit.release("pomodoro")
    }

    function toggleRunning() {
        if (root.running) root.pause()
        else root.start()
    }

    function reset() {
        tickTimer.stop()
        root.running = false
        root.phase = root.phaseIdle
        root.remainingSeconds = 0
        root.cyclesCompleted = 0
        IdleInhibit.release("pomodoro")
    }

    function skip() { root.advancePhase() }

    Timer {
        id: tickTimer
        interval: 1000
        repeat: true
        onTriggered: {
            if (root.remainingSeconds > 0) root.remainingSeconds -= 1
            else root.advancePhase()
        }
    }

    function advancePhase() {
        if (root.phase === root.phaseFocus) {
            root.cyclesCompleted += 1
            root.notify("Focus session complete",
                root.isLongBreak ? "Time for a long break" : "Time for a short break")
            root.phase = root.phaseBreak
            root.remainingSeconds = (root.isLongBreak
                ? settings.longBreakMinutes : settings.breakMinutes) * 60
            IdleInhibit.release("pomodoro")
        } else {
            root.notify("Break's over", "Back to focus")
            root.phase = root.phaseFocus
            root.remainingSeconds = settings.focusMinutes * 60
            if (root.running) IdleInhibit.inhibit("pomodoro")
        }
    }

    Process {
        id: notifyProc
        command: []
    }
    function notify(summary, body) {
        notifyProc.command = ["notify-send", "-a", "Pomodoro", summary, body]
        notifyProc.running = true
    }
}
