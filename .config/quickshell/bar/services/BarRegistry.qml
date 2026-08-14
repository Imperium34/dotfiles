pragma Singleton

import Quickshell
import Quickshell.Hyprland

// Bar.qml's Variants delegate creates one PanelWindow per screen. The popups
// are single instances living at Scope level, so they need a way to ask "which
// bar should I anchor to right now" that's this.
Singleton {
    id: root

    property var bars: ({})

    function register(name, win) {
        const m = Object.assign({}, root.bars)
        m[name] = win
        root.bars = m
    }

    function unregister(name) {
        const m = Object.assign({}, root.bars)
        delete m[name]
        root.bars = m
    }

    readonly property var focusedBar: {
        const mon = Hyprland.focusedMonitor
        if (mon && root.bars[mon.name]) return root.bars[mon.name]

        const keys = Object.keys(root.bars)
        return keys.length > 0 ? root.bars[keys[0]] : null
    }
}
