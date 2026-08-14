pragma Singleton

import Quickshell
import Quickshell.Networking
import QtQuick

Singleton {
    id: root

    // ── DEVICES ────────────────────────────────────────────────
    readonly property var wifiDevice: {
        for (const d of Networking.devices.values) {
            if (d.type === DeviceType.Wifi) return d
        }
        return null
    }

    readonly property var ethernetDevice: {
        for (const d of Networking.devices.values) {
            if (d.type === DeviceType.Ethernet) return d
        }
        return null
    }

    readonly property bool hasWifi: wifiDevice !== null
    readonly property bool hasEthernet: ethernetDevice !== null
    readonly property bool hasAnyDevice: hasWifi || hasEthernet

    // ── WI-FI ──────────────────────────────────────────────────
    readonly property bool wifiEnabled: Networking.wifiEnabled

    readonly property bool hardwareBlocked: hasWifi && !Networking.wifiHardwareEnabled

    function setWifiEnabled(enabled) { Networking.wifiEnabled = enabled }
    function toggleWifi() { Networking.wifiEnabled = !Networking.wifiEnabled }

    readonly property bool wifiConnected: wifiDevice ? wifiDevice.connected : false

    readonly property var activeNetwork: {
        if (!wifiDevice || !wifiConnected) return null
        for (const n of wifiDevice.networks.values) {
            if (n.connected) return n
        }
        return null
    }

    readonly property string ssid: activeNetwork ? activeNetwork.name : ""
    readonly property real strength: activeNetwork ? activeNetwork.signalStrength : 0

    // ── ETHERNET ───────────────────────────────────────────────
    readonly property bool ethernetConnected: ethernetDevice ? ethernetDevice.connected : false

    // ── PRESENTATION ───────────────────────────────────────────
    readonly property bool connected: ethernetConnected || wifiConnected

    readonly property bool showEthernet: ethernetConnected || (hasEthernet && !hasWifi)

    readonly property string icon: {
        if (root.showEthernet) return root.ethernetConnected ? "󰈁" : "󰈂"
        if (!root.hasWifi) return "󰤮"
        if (root.hardwareBlocked) return "󰤮"
        if (!root.wifiEnabled) return "󰤮"
        if (!root.wifiConnected) return "󰤭"
        if (root.strength < 0.25) return "󰤟"
        if (root.strength < 0.5) return "󰤢"
        if (root.strength < 0.75) return "󰤥"
        return "󰤨"
    }

    readonly property string label: {
        if (root.showEthernet) return root.ethernetConnected ? "Ethernet" : "Unplugged"
        if (!root.hasWifi) return "No adapter"
        if (root.hardwareBlocked) return "Blocked"
        if (!root.wifiEnabled) return "Disabled"
        if (!root.wifiConnected) return "Disconnected"
        return root.ssid
    }

    // ── SCANNING ───────────────────────────────────────────────
    property bool scanning: false
    onScanningChanged: if (wifiDevice) wifiDevice.scannerEnabled = scanning
    onWifiDeviceChanged: if (wifiDevice) wifiDevice.scannerEnabled = scanning

    // ── NETWORK LIST ───────────────────────────────────────────
    readonly property var networks: {
        if (!wifiDevice) return []

        const bucket = s => Math.round((s || 0) * 4)
        const raw = wifiDevice.networks.values.slice()

        raw.sort((a, b) => {
            if (a.known !== b.known) return a.known ? -1 : 1
            if (bucket(a.signalStrength) !== bucket(b.signalStrength))
                return bucket(b.signalStrength) - bucket(a.signalStrength)
            return (a.name || "").localeCompare(b.name || "")
        })

        return raw
    }
}
