import qs
import qs.widgets
import qs.popups.battery
import Quickshell
import Quickshell.Services.UPower
import QtQuick

BarButton {
    id: root

    implicitWidth: pill.implicitWidth
    implicitHeight: pill.implicitHeight

    visible: bat ? bat.isLaptopBattery : false

    readonly property var bat: UPower.displayDevice
    readonly property bool ready: !!bat && bat.ready

    readonly property bool charging: ready && bat.state === UPowerDeviceState.Charging
    readonly property bool full: ready && bat.state === UPowerDeviceState.FullyCharged

    readonly property bool pluggedIdle: ready && bat.state === UPowerDeviceState.PendingCharge

    readonly property bool low: ready && !charging && !full && !pluggedIdle
        && bat.percentage * 100 <= BatteryAlert.lowThreshold

    readonly property string batteryIcon: {
        if (!ready) return "󰂑";
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
        if (!ready) return Theme.foreground;
        if (low) return Theme.color1;
        if (charging) return Theme.color2;
        if (pluggedIdle) return Theme.color5;
        if (bat.percentage * 100 <= 30) return Theme.color3;
        return Theme.foreground;
    }

    popup: BatteryPopup {}

    Rectangle {
        id: pill
        implicitWidth: widget.implicitWidth + (pill.activeState ? 16 : 8)
        implicitHeight: widget.implicitHeight + 6
        radius: height / 2
        color: "transparent"

        Behavior on implicitWidth { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        readonly property bool activeState: root.low || root.charging
        readonly property color stateColor: root.low
            ? Theme.color1
            : (root.charging ? Theme.color2 : "transparent")

        Rectangle {
            id: fill
            anchors.fill: parent
            radius: parent.radius
            color: pill.stateColor
            visible: pill.activeState
            opacity: 1.0

            Behavior on color { ColorAnimation { duration: 300 } }

            SequentialAnimation {
                id: breatheAnim
                running: pill.activeState
                loops: Animation.Infinite
                alwaysRunToEnd: true
                NumberAnimation { target: fill; property: "opacity"; to: 0.5; duration: 2000; easing.type: Easing.InOutSine }
                NumberAnimation { target: fill; property: "opacity"; to: 0.75; duration: 2000; easing.type: Easing.InOutSine }
            }
        }

        ExpandingWidget {
            id: widget
            anchors.centerIn: parent
            icon: root.batteryIcon
            label: root.ready ? Math.round(root.bat.percentage * 100) + "%" : "--"
            iconColor: root.batteryColor

            Behavior on iconColor { ColorAnimation { duration: 300 } }
        }
    }
}
