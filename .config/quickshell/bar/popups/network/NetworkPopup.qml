import "../../widgets"
import qs
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

BasePopup {
    id: popup

    implicitWidth: 320

    implicitHeight: header.height + networkList.height + footer.height

    onAnimInChanged: Net.scanning = animIn

    readonly property var networkModel: Net.networks

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
                text: "Wi-Fi"
                color: Theme.foreground
                font.pixelSize: 15
                font.bold: true
                Layout.fillWidth: true
            }

            Item {
                width: 44
                height: 26

                Rectangle {
                    id: toggleTrack
                    anchors.fill: parent
                    radius: 13
                    color: {
                        if (Net.hardwareBlocked)
                            return Theme.hexToRgba(Theme.foreground, 0.15)
                        return Net.wifiEnabled
                            ? Theme.color5
                            : Theme.hexToRgba(Theme.foreground, 0.2)
                    }

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                }

                Rectangle {
                    id: toggleThumb
                    width: 20
                    height: 20
                    radius: 10
                    color: Net.hardwareBlocked
                        ? Theme.hexToRgba(Theme.foreground, 0.4)
                        : Theme.background
                    anchors.verticalCenter: parent.verticalCenter
                    x: Net.wifiEnabled ? parent.width - width - 3 : 3

                    Behavior on x {
                        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                    }
                }

                TapHandler {
                    enabled: !Net.hardwareBlocked
                    onTapped: Net.wifiEnabled = !Net.wifiEnabled
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
            id: networkList
            anchors.top: headerDivider.bottom
            anchors.left: parent.left
            anchors.right: parent.right

            readonly property int rowHeight: 52
            readonly property int maxVisible: 6
            height: Math.min(contentHeight, 6 * 52)

            clip: true
            model: networkModel
            interactive: count > maxVisible

            Text {
                anchors.centerIn: parent
                text: !Networking.wifiEnabled
                    ? "Wi-Fi is off"
                    : Net.wifiDevice === null
                    ? "No adapter"
                    : "Scanning…"
                color: Theme.hexToRgba(Theme.foreground, 0.4)
                font.pixelSize: 13
                visible: networkList.count === 0
            }

            delegate: Item {
                width: networkList.width
                height: rowInstance.height
                readonly property var net: networkModel[index]

                NetworkRow {
                    id: rowInstance
                    width: parent.width
                    network: parent.net
                }
            }
        }

        Rectangle {
            id: footerDivider
            anchors.top: networkList.bottom
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
                id: nmtui
                command: ["/usr/bin/alacritty", "-e", "/usr/bin/nmtui"]
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
                    text: "󰒓"
                    color: Theme.hexToRgba(Theme.foreground, 0.6)
                    font.pixelSize: 14
                    font.family: "Symbols Nerd Font"
                }

                Text {
                    text: "Network Settings"
                    color: Theme.hexToRgba(Theme.foreground, 0.6)
                    font.pixelSize: 13
                }
            }

            TapHandler {
                onTapped: {
                    popup.close()
                    nmtui.startDetached()
                }
            }
        }
    }
}
