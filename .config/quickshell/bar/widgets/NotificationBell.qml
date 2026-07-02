import "../popups/notifications"
import qs
import Quickshell
import QtQuick

Item {
    id: root
    required property var barWindow

    implicitWidth: widget.implicitWidth
    implicitHeight: widget.implicitHeight

    readonly property bool dnd: NotifService.dnd
    readonly property int count: NotifService.count

    readonly property string bellIcon: {
        if (dnd)        return "󰂛"
        if (count > 0)  return "󰂚"
        return "󰂜"
    }
    readonly property string bellColor: dnd
        ? Theme.color1
        : count > 0 ? Theme.color5 : Theme.foreground
    readonly property string bellLabel: {
        if (dnd)        return "DND"
        if (count > 0)  return count + ""
        return ""
    }

    ExpandingWidget {
        id: widget
        icon: bellIcon
        label: bellLabel
        iconColor: bellColor
    }

    NotifCenter {
        id: center
        barWindow: root.barWindow
        anchorX: (root.barWindow.screen ? root.barWindow.screen.width : 1920) - 380 - 10
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: center.toggle()
    }

    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: NotifService.toggleDnd()
    }
}
