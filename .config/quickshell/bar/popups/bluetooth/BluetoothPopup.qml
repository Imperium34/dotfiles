import "../../widgets"
import qs
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

BasePopup {
    id: popup

    implicitWidth: 300
    implicitHeight: header.height + deviceList.height + footer.height

    readonly property var deviceModel: BtService.devices

    Rectangle {
        id: card
        anchors.fill: parent
        radius: 16
        color: Theme.hexToRgba(Theme.background, 0.92)
        border.color: Theme.hexToRgba(Theme.foreground, 0.1)
        border.width: 1
        clip: true

        opacity: popup.animIn ? 1 : 0
        scale: popup.animIn ? 1 : 0.95
        transformOrigin: Item.Top

        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        RowLayout {
            id: header
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: 52
            anchors.leftMargin: 16
            anchors.rightMargin: 16

            Text {
                text: "Bluetooth"
                color: Theme.foreground
                font.pixelSize: 15
                font.bold: true
                Layout.fillWidth: true
            }

            Item {
                width: 44
                height: 26

                Rectangle {
                    anchors.fill: parent
                    radius: 13
                    color: BtService.enabled
                        ? Theme.color5
                        : Theme.hexToRgba(Theme.foreground, 0.2)

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                }

                Rectangle {
                    width: 20
                    height: 20
                    radius: 10
                    color: Theme.background
                    anchors.verticalCenter: parent.verticalCenter
                    x: BtService.enabled ? parent.width - width - 3 : 3

                    Behavior on x {
                        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                    }
                }

                TapHandler {
                    onTapped: BtService.toggleEnabled()
                }
            }
        }

        Rectangle {
            id: headerDivider
            anchors.top: header.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            height: 1
            color: Theme.hexToRgba(Theme.foreground, 0.08)
        }

        ListView {
            id: deviceList
            anchors.top: headerDivider.bottom
            anchors.left: parent.left
            anchors.right: parent.right

            readonly property int rowHeight: 56
            readonly property int maxVisible: 6
            height: Math.min(contentHeight, maxVisible * rowHeight)

            clip: true
            model: deviceModel
            interactive: count > maxVisible

            Text {
                anchors.centerIn: parent
                text: !BtService.enabled
                    ? "Bluetooth is off"
                    : BtService.adapter === null
                    ? "No adapter"
                    : "No devices"
                color: Theme.hexToRgba(Theme.foreground, 0.4)
                font.pixelSize: 13
                visible: deviceList.count === 0
            }

            delegate: Item {
                width: deviceList.width
                height: rowInstance.height

                readonly property var dev: deviceModel[index]

                BluetoothRow {
                    id: rowInstance
                    width: parent.width
                    device: parent.dev
                }
            }
        }

        Rectangle {
            id: footerDivider
            anchors.top: deviceList.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            height: 1
            color: Theme.hexToRgba(Theme.foreground, 0.08)
        }

        Item {
            id: footer
            anchors.top: footerDivider.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 44

            Process {
                id: bluetui
                command: ["/usr/bin/alacritty", "--class", "bluetui", "-e", "/usr/bin/bluetui"]
            }

            HoverHandler { id: footerHover }

            Rectangle {
                anchors.fill: parent
                anchors.margins: 4
                radius: 10
                color: footerHover.hovered
                    ? Theme.hexToRgba(Theme.foreground, 0.07)
                    : "transparent"

                Behavior on color {
                    ColorAnimation { duration: 100 }
                }
            }

            RowLayout {
                anchors.centerIn: parent
                spacing: 6

                Text {
                    text: "󰂰"
                    color: Theme.hexToRgba(Theme.foreground, 0.6)
                    font.pixelSize: 14
                    font.family: "Symbols Nerd Font"
                }

                Text {
                    text: "Bluetooth Settings"
                    color: Theme.hexToRgba(Theme.foreground, 0.6)
                    font.pixelSize: 13
                }
            }

            TapHandler {
                onTapped: {
                    popup.close()
                    bluetui.startDetached()
                }
            }
        }
    }
}
