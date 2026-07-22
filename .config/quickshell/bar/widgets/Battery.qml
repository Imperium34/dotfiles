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
        if (critical) return Theme.color4;
        if (charging) return Theme.color4;
        if (bat.percentage * 100 <= 30) return Theme.color3;
        return Theme.foreground;
    }

    popup: BatteryPopup {}

    Rectangle {
        id: pill
        implicitWidth: widget.implicitWidth + (critical || charging ? 16 : 8)
        implicitHeight: widget.implicitHeight + 6
        radius: height / 2
        color: "transparent"

        Behavior on implicitWidth { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        readonly property bool activeState: critical || (charging && !full)
        readonly property color stateColor: critical ? Theme.color1 : (charging && !full ? Theme.color2 : "transparent")

        Rectangle {
            id: fill
            anchors.fill: parent
            radius: parent.radius
            color: pill.stateColor
            visible: pill.activeState

            Behavior on color { ColorAnimation { duration: 300 } }

            SequentialAnimation {
                id: breatheAnim
                running: pill.activeState
                loops: Animation.Infinite
                alwaysRunToEnd: true
                NumberAnimation { target: fill; property: "opacity"; to: 0.5; duration: 2000; easing.type: Easing.InOutSine }
                NumberAnimation { target: fill; property: "opacity"; to: 0.75; duration: 2000; easing.type: Easing.InOutSine }
            }

            Component.onCompleted: {
                opacity = 1.0
                if (pill.activeState) breatheAnim.restart()
            }
        }

        ExpandingWidget {
            id: widget
            anchors.centerIn: parent
            icon: batteryIcon
            label: bat && bat.ready ? Math.round(bat.percentage * 100) + "%" : "--"
            iconColor: batteryColor

            Behavior on iconColor { ColorAnimation { duration: 300 } }
        }
    }
}
