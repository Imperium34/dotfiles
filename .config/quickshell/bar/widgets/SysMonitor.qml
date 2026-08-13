import qs
import qs.widgets
import qs.services
import qs.popups.sysmonitor
import Quickshell
import QtQuick

BarButton {
    id: root

    property string side: "cpu"

    readonly property bool isCpu: side === "cpu"
    readonly property real ringValue: isCpu ? SysInfo.cpuUsage : SysInfo.memUsage

    implicitWidth: 22
    implicitHeight: 22

    scale: root.pressed ? 0.88 : 1
    Behavior on scale {
        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
    }

    popup: SysMonitorPopup {}

    Ring {
        id: ring
        anchors.fill: parent
        value: root.ringValue
        thickness: 3

        Text {
            anchors.centerIn: parent
            text: root.isCpu ? "󰍛" : "󰘚"
            color: ring.activeColor
            font.pixelSize: 9
            font.family: "Symbols Nerd Font"
        }
    }
}
