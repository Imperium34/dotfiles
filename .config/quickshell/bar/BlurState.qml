pragma Singleton

import Quickshell
import Quickshell.Services.UPower
import Quickshell.Io

Singleton {
    id: root

    readonly property var bat: UPower.displayDevice

    readonly property bool onBattery: bat && bat.ready
        && bat.state === UPowerDeviceState.Discharging
    readonly property bool heavyEffectsEnabled: !onBattery
    readonly property bool blurEnabled: heavyEffectsEnabled

    Process { id: videoProc; command: [] }

    onHeavyEffectsEnabledChanged: {
        videoProc.command = [
            Quickshell.env("HOME") + "/.config/quickshell/scripts/video-wallpaper.sh",
            heavyEffectsEnabled ? "resume" : "stop"
        ]
        videoProc.running = true
    }
}
