import qs
import qs.widgets
import qs.services
import qs.popups.bluetooth
import Quickshell
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts

BarButton {
    id: root

    implicitWidth: row.implicitWidth + 8
    implicitHeight: row.implicitHeight

    popup: BluetoothPopup {}

    onRightClicked: BtService.toggleEnabled()

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 4

        Text {
            text: BtService.icon
            color: BtService.connectedCount > 0
                ? Theme.color5
                : BtService.enabled
                ? Theme.foreground
                : Theme.hexToRgba(Theme.foreground, 0.4)
            font.pixelSize: 15
            font.family: "Symbols Nerd Font"
        }

        Text {
            text: BtService.connectedCount === 1
                ? BtService.connectedDevices[0].name
                : BtService.connectedCount > 1
                ? BtService.connectedCount + " devices"
                : ""
            color: Theme.foreground
            font.pixelSize: 14
            visible: text !== ""
        }
    }
}
