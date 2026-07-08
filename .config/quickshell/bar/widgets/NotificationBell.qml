import "../popups/notifications"
import qs
import qs.widgets
import Quickshell
import QtQuick

BarButton {
    id: root

    implicitWidth: widget.implicitWidth
    implicitHeight: widget.implicitHeight

    readonly property bool dnd: NotifService.dnd
    readonly property int count: NotifService.count

    readonly property string bellIcon: {
        if (dnd)        return "󰂛"
        if (count > 0)  return "󰂚"
        return "󰂜"
    }
    readonly property color bellColor: dnd
        ? Theme.color1
        : count > 0 ? Theme.color5 : Theme.foreground
    readonly property string bellLabel: {
        if (dnd)        return "DND"
        if (count > 0)  return count + ""
        return ""
    }

    popup: NotifCenter {}

    onRightClicked: NotifService.toggleDnd()

    ExpandingWidget {
        id: widget
        icon: bellIcon
        label: bellLabel
        iconColor: bellColor
    }
}
