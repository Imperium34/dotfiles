pragma Singleton

import qs
import Quickshell
import Quickshell.Bluetooth
import QtQuick

Singleton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter

    readonly property bool enabled: adapter ? adapter.enabled : false
    readonly property bool discovering: adapter ? adapter.discovering : false

    function toggleEnabled() {
        if (adapter) adapter.enabled = !adapter.enabled
    }

    function toggleDiscovering() {
        if (adapter) adapter.discovering = !adapter.discovering
    }

    readonly property var devices: {
        const raw = Bluetooth.devices.values.slice()
        raw.sort((a, b) => {
            if (a.connected !== b.connected) return a.connected ? -1 : 1
            return (a.name ?? "").localeCompare(b.name ?? "")
        })
        return raw
    }

    readonly property var connectedDevices: Bluetooth.devices.values.filter(d => d.connected)
    readonly property int connectedCount: connectedDevices.length

    readonly property string icon: {
        if (!adapter)        return "󰂲"
        if (!enabled)        return "󰂲"
        if (connectedCount > 0) return "󰂱"
        return "󰂯"
    }
}
