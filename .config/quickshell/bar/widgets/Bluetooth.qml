import "../popups/bluetooth"
import qs
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    required property var barWindow

    implicitWidth: row.implicitWidth + 8
    implicitHeight: row.implicitHeight

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

    BluetoothPopup {
        id: popup
        barWindow: root.barWindow
        anchorX: (root.barWindow.screen ? root.barWindow.screen.width : 1920) - 300 - 10
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: popup.toggle()
    }

    // Right-click still toggles adapter on/off — keep the old shortcut
    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: BtService.toggleEnabled()
    }
}
