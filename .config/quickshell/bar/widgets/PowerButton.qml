import "../popups/power"
import qs
import qs.widgets
import Quickshell
import QtQuick

BarButton {
    id: root

    implicitWidth: bg.implicitWidth
    implicitHeight: bg.implicitHeight

    popup: PowerMenu {}

    HoverHandler { id: hover }

    Rectangle {
        id: bg
        implicitWidth: icon.implicitWidth + 24
        implicitHeight: icon.implicitHeight + 8
        radius: height / 2
        color: hover.hovered
            ? Theme.color4
            : Theme.hexToRgba(Theme.color4, 0.7)

        Behavior on color {
            ColorAnimation { duration: 150 }
        }

        Text {
            id: icon
            anchors.centerIn: parent
            text: "󰐥"
            color: Theme.background
            font.pixelSize: 15
            font.family: "Symbols Nerd Font"
        }
    }
}
