import qs
import Quickshell
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    required property var device

    readonly property bool isConnected: device ? (device.connected ?? false) : false
    readonly property bool isPairing: device ? (device.pairing ?? false) : false

    height: 56

    HoverHandler { id: rowHover }

    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        radius: 8
        color: rowHover.hovered
            ? Theme.hexToRgba(Theme.foreground, 0.07)
            : "transparent"

        Behavior on color {
            ColorAnimation { duration: 100 }
        }
    }

    RowLayout {
        anchors {
            fill: parent
            leftMargin: 16
            rightMargin: 16
        }
        spacing: 10

        Image {
            width: 20
            height: 20
            source: device ? Quickshell.iconPath(device.icon, 32) : ""
            visible: device && device.icon !== ""
        }

        Text {
            text: "󰂯"
            color: isConnected ? Theme.color5 : Theme.hexToRgba(Theme.foreground, 0.7)
            font.pixelSize: 16
            font.family: "Symbols Nerd Font"
            visible: !device || device.icon === ""
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: device ? (device.name ?? device.deviceName ?? "") : ""
                color: isConnected ? Theme.foreground : Theme.hexToRgba(Theme.foreground, 0.85)
                font.pixelSize: 13
                font.bold: isConnected
                elide: Text.ElideRight
            }

            RowLayout {
                spacing: 4
                visible: isConnected && device && device.batteryAvailable

                Text {
                    text: {
                        if (!device || !device.batteryAvailable) return ""
                        const b = device.battery
                        if (b > 0.8) return "󰁹"
                        if (b > 0.6) return "󰂀"
                        if (b > 0.4) return "󰁾"
                        if (b > 0.2) return "󰁼"
                        return "󰁺"
                    }
                    color: {
                        if (!device || !device.batteryAvailable) return Theme.foreground
                        return device.battery < 0.2 ? Theme.color1 : Theme.hexToRgba(Theme.foreground, 0.5)
                    }
                    font.pixelSize: 11
                    font.family: "Symbols Nerd Font"
                }

                Text {
                    text: device && device.batteryAvailable
                        ? Math.round(device.battery * 100) + "%"
                        : ""
                    color: Theme.hexToRgba(Theme.foreground, 0.5)
                    font.pixelSize: 11
                }
            }
        }

        Loader {
            active: isConnected || isPairing
            sourceComponent: isPairing ? spinnerComponent : checkComponent
        }
    }

    TapHandler {
        onTapped: {
            if (!device) return
            if (isPairing) {
                device.cancelPair()
            } else if (isConnected) {
                device.disconnect()
            } else {
                device.connect()
            }
        }
    }

    Component {
        id: checkComponent
        Text {
            text: "󰄬"
            color: Theme.color5
            font.pixelSize: 14
            font.family: "Symbols Nerd Font"
        }
    }

    Component {
        id: spinnerComponent
        Text {
            text: "󰑙"
            color: Theme.hexToRgba(Theme.foreground, 0.6)
            font.pixelSize: 14
            font.family: "Symbols Nerd Font"
            RotationAnimator on rotation {
                from: 0; to: 360
                duration: 1000
                loops: Animation.Infinite
                running: true
            }
        }
    }
}
