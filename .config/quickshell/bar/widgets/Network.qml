import qs
import qs.widgets
import qs.services
import qs.components
import qs.popups.network
import Quickshell
import QtQuick
import QtQuick.Layouts

BarButton {
    id: root

    visible: Net.hasAnyDevice

    implicitWidth: row.implicitWidth + 8
    implicitHeight: row.implicitHeight

    popup: NetworkPopup {}

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 4

        Text {
            text: Net.icon
            color: Net.connected
                ? Theme.foreground
                : (Net.hardwareBlocked
                    ? Theme.hexToRgba(Theme.foreground, 0.3)
                    : Theme.color1)
            font.pixelSize: 15
            font.family: "Symbols Nerd Font"
        }

        Text {
            text: Net.label
            color: Net.connected
                ? Theme.foreground
                : Theme.hexToRgba(Theme.foreground, 0.5)
            font.pixelSize: 14
            visible: text !== ""
        }
    }
}
