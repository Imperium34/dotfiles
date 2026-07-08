import qs
import qs.widgets
import qs.popups.battery
import Quickshell
import Quickshell.Services.UPower
import QtQuick

BarButton {
    id: root

    implicitWidth: widget.implicitWidth
    implicitHeight: widget.implicitHeight

    visible: bat ? bat.isLaptopBattery : false

    readonly property var bat: UPower.displayDevice
    readonly property bool charging: bat && bat.ready
        && (bat.state === UPowerDeviceState.Charging
            || bat.state === UPowerDeviceState.PendingCharge)
    readonly property bool full: bat && bat.ready && bat.state === UPowerDeviceState.FullyCharged
    readonly property bool critical: bat && bat.ready && !charging && !full
        && bat.percentage * 100 <= 15

    readonly property string batteryIcon: {
        if (!bat || !bat.ready) return "󰂑";
        if (full || (charging && bat.percentage * 100 >= 95)) return "󰁹";
        const p = bat.percentage * 100;
        if (p < 10) return charging ? "󰢜" : "󰂎";
        if (p < 30) return charging ? "󰂆" : "󰁻";
        if (p < 50) return charging ? "󰂇" : "󰁽";
        if (p < 70) return charging ? "󰂈" : "󰁿";
        if (p < 90) return charging ? "󰂉" : "󰂁";
        return charging ? "󰂊" : "󰁹";
    }

    readonly property color batteryColor: {
        if (!bat || !bat.ready) return Theme.foreground;
        if (bat.percentage * 100 <= 15) return Theme.color1;
        if (bat.percentage * 100 <= 30) return Theme.color3;
        return charging ? Theme.color2 : Theme.foreground;
    }

    popup: BatteryPopup {}

    ExpandingWidget {
        id: widget
        icon: batteryIcon
        label: bat && bat.ready ? Math.round(bat.percentage * 100) + "%" : "--"
        iconColor: batteryColor

        Behavior on iconColor {
            ColorAnimation { duration: 400; easing.type: Easing.OutCubic }
        }

        transformOrigin: Item.Center

        Behavior on scale {
            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
        }
        Behavior on opacity {
            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
        }

        SequentialAnimation {
            running: charging && !full
            loops: Animation.Infinite
            alwaysRunToEnd: true

            NumberAnimation { target: widget; property: "scale"; to: 1.1; duration: 850; easing.type: Easing.InOutSine }
            NumberAnimation { target: widget; property: "scale"; to: 1.0; duration: 850; easing.type: Easing.InOutSine }
        }

        SequentialAnimation {
            running: critical
            loops: Animation.Infinite
            alwaysRunToEnd: true

            NumberAnimation { target: widget; property: "opacity"; to: 0.35; duration: 450; easing.type: Easing.InOutSine }
            NumberAnimation { target: widget; property: "opacity"; to: 1.0; duration: 450; easing.type: Easing.InOutSine }
        }
    }
}
