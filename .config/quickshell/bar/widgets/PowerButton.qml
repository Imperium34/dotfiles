import "../popups/power"
import qs
import Quickshell
import QtQuick

Item {
    id: root
    required property var barWindow
    implicitWidth: bg.implicitWidth
    implicitHeight: bg.implicitHeight

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

    PowerMenu {
        id: popup
        barWindow: root.barWindow
        anchorX: 0
    }

    TapHandler {
        onTapped: popup.toggle()
    }
}
