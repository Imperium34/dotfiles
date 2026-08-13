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

    readonly property bool connected: wifiDevice ? wifiDevice.connected : false

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
