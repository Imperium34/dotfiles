pragma Singleton

import Quickshell
import Quickshell.Services.UPower

Singleton {
    id: root

    readonly property var bat: UPower.displayDevice

    readonly property bool onBattery: bat && bat.ready
        && bat.state === UPowerDeviceState.Discharging
    readonly property bool blurEnabled: !onBattery
}
