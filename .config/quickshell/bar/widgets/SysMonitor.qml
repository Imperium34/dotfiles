import qs
import qs.widgets
import qs.popups.sysmonitor
import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property var barWindow
    property string side: "cpu"

    readonly property bool isCpu: side === "cpu"
    readonly property real ringValue: isCpu ? SysInfo.cpuUsage : SysInfo.memUsage

    implicitWidth: 22
    implicitHeight: 22

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

    scale: tap.pressed ? 0.88 : 1
    Behavior on scale {
        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
    }

    TapHandler {
        id: tap
        onTapped: popup.toggle()
    }

    SysMonitorPopup {
        id: popup
        barWindow: root.barWindow
        anchorX: ((root.barWindow.screen ? root.barWindow.screen.width : 1920) - popup.implicitWidth) / 2
    }
}
