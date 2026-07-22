pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import QtQuick

Singleton {
    id: root

    readonly property var bat: UPower.displayDevice
    property bool warnedLow: false
    property bool warnedCritical: false

    Process { id: notifyProc }

    Connections {
        target: bat
        function onPercentageChanged() {
            if (!bat || !bat.ready) return

            const pct = bat.percentage * 100
            const charging = bat.state === UPowerDeviceState.Charging
                || bat.state === UPowerDeviceState.PendingCharge

            if (charging) {
                root.warnedLow = false
                root.warnedCritical = false
                return
            }

            if (pct <= 5 && !root.warnedCritical) {
                root.warnedCritical = true
                notifyProc.command = ["notify-send", "-u", "critical",
                    "Battery critical", Math.round(pct) + "% remaining"]
                notifyProc.running = true
            } else if (pct <= 15 && !root.warnedLow) {
                root.warnedLow = true
                notifyProc.command = ["notify-send", "-u", "normal",
                    "Battery low", Math.round(pct) + "% remaining"]
                notifyProc.running = true
            }
        }
    }
}
