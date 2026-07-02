pragma Singleton

import qs
import Quickshell
import Quickshell.Networking
import QtQuick

Singleton {
    id: root

    readonly property var wifiDevice: {
        const devices = Networking.devices.values
        for (const d of devices) {
            if (d.type === DeviceType.Wifi) return d
        }
        return null
    }

    readonly property bool hardwareBlocked: !Networking.wifiHardwareEnabled
    property bool wifiEnabled: Networking.wifiEnabled
    onWifiEnabledChanged: Networking.wifiEnabled = wifiEnabled

    // Device-level connection state is a first-class reactive property — bind
    // to it directly instead of inferring "connected" by scanning the network
    // list. `connected` flips (with a real change signal) the moment the link
    // changes, so everything derived from it updates immediately.
    readonly property bool connected: wifiDevice ? wifiDevice.connected : false

    // activeNetwork still has to find WHICH network is active by scanning the
    // list (.values has no member-state reactivity). But it now depends on the
    // device's `connected`, which re-evaluates this binding at exactly the
    // moment the active network appears/disappears. The device property is the
    // reactive trigger the list scan was missing.
    readonly property var activeNetwork: {
        if (!wifiDevice || !connected) return null
        const nets = wifiDevice.networks.values
        for (const n of nets) {
            if (n.connected) return n
        }
        return null
    }

    readonly property string ssid: activeNetwork ? activeNetwork.name : ""
    readonly property real strength: activeNetwork ? activeNetwork.signalStrength : 0

    readonly property string icon: {
        if (hardwareBlocked)           return "󰤮"
        if (!Networking.wifiEnabled)   return "󰤮"
        if (!connected)                return "󰤭"
        if (strength < 0.25)           return "󰤟"
        if (strength < 0.5)            return "󰤢"
        if (strength < 0.75)           return "󰤥"
        return "󰤨"
    }

    // .values is itself reactive (re-emits on add/remove), so iterating it in a
    // binding already re-evaluates when the network set changes — no _count
    // dependency proxy needed. Sorting by `known` then signal is stable enough
    // that membership-level reactivity covers the visible list.
    readonly property var networks: {
        if (!wifiDevice) return []
        const raw = wifiDevice.networks.values.slice()
        raw.sort((a, b) => {
            if (a.known !== b.known) return a.known ? -1 : 1
            return b.signalStrength - a.signalStrength
        })
        return raw
    }

    property bool scanning: false
    onScanningChanged: {
        if (wifiDevice) wifiDevice.scannerEnabled = scanning
    }
    onWifiDeviceChanged: {
        if (wifiDevice) wifiDevice.scannerEnabled = scanning
    }
}
