pragma Singleton

import qs.services
import Quickshell

// Composed entirely from Net and BtService, both of which already drive
// NetworkManager and BlueZ over D-Bus. No rfkill, no nmcli, no process spawns
// which also sidesteps the permission question, since rfkill often isn't usable
// by an unprivileged user while the D-Bus paths are polkit-backed.
//
// Doesn't touch WWAN; there's no cellular modem on either machine here. If one
// ever appears this would need a real rfkill path.
Singleton {
    id: root

    readonly property bool hasWifi: Net.hasWifi
    readonly property bool hasBluetooth: BtService.adapter !== null
    readonly property bool anyRadio: hasWifi || hasBluetooth

    readonly property bool active: {
        if (!root.anyRadio) return false
        const wifiOff = !root.hasWifi || !Net.wifiEnabled
        const btOff = !root.hasBluetooth || !BtService.enabled
        return wifiOff && btOff
    }

    function setActive(on) {
        if (root.hasWifi) Net.setWifiEnabled(!on)
        if (root.hasBluetooth) BtService.adapter.enabled = !on
    }

    function toggle() { root.setActive(!root.active) }
}
