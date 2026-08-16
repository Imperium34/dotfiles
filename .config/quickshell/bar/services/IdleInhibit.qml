pragma Singleton

import Quickshell
import Quickshell.Wayland

Singleton {
    id: root

    property var sources: ({})
    readonly property bool inhibiting: Object.keys(root.sources).length > 0

    function inhibit(sourceId) {
        const s = Object.assign({}, root.sources)
        s[sourceId] = true
        root.sources = s
    }

    function release(sourceId) {
        if (!(sourceId in root.sources)) return
        const s = Object.assign({}, root.sources)
        delete s[sourceId]
        root.sources = s
    }

    function toggle(sourceId) {
        if (root.sources[sourceId]) root.release(sourceId)
        else root.inhibit(sourceId)
    }

    property var window: null

    IdleInhibitor {
        window: root.window
        enabled: root.inhibiting
    }
}
