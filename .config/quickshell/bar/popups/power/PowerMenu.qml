import qs
import "../../widgets"
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

BasePopup {
    id: popup

    implicitWidth: 160
    implicitHeight: actionsCol.implicitHeight + 16

    anchor.rect.x: 0
    anchor.rect.y: barWindow.height + 8

    readonly property var actions: [
        { icon: "󰌾", label: "Lock",      cmd: ["loginctl", "lock-session"] },
        { icon: "󰒲", label: "Suspend",   cmd: ["systemctl", "suspend"] },
        { icon: "󰋊", label: "Hibernate", cmd: ["systemctl", "hibernate"] },
        { icon: "󰍃", label: "Logout",    cmd: ["bash", "-c", "loginctl terminate-user $USER"] },
        { icon: "󰑐", label: "Reboot",    cmd: ["systemctl", "reboot"] },
        { icon: "󰐥", label: "Shutdown",  cmd: ["systemctl", "poweroff"] },
    ]

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

        ColumnLayout {
            id: actionsCol
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 8
            }
            spacing: 4

            Repeater {
                model: popup.actions

                delegate: Item {
                    readonly property var action: popup.actions[index]
                    Layout.fillWidth: true
                    height: 40

                    HoverHandler { id: actionHover }

                    Rectangle {
                        anchors.fill: parent
                        radius: 10
                        color: {
                            if (!actionHover.hovered) return "transparent"
                            if (action.label === "Reboot" || action.label === "Shutdown")
                                return Theme.hexToRgba(Theme.color1, 0.15)
                            return Theme.hexToRgba(Theme.foreground, 0.08)
                        }
                        Behavior on color {
                            ColorAnimation { duration: 100 }
                        }
                    }

                    RowLayout {
                        anchors {
                            fill: parent
                            leftMargin: 10
                            rightMargin: 10
                        }
                        spacing: 8

                        Text {
                            text: action.icon
                            font.pixelSize: 15
                            font.family: "Symbols Nerd Font"
                            color: {
                                if (!actionHover.hovered) return Theme.hexToRgba(Theme.foreground, 0.7)
                                if (action.label === "Reboot" || action.label === "Shutdown")
                                    return Theme.color1
                                return Theme.color5
                            }
                            Behavior on color {
                                ColorAnimation { duration: 100 }
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: action.label
                            font.pixelSize: 13
                            color: actionHover.hovered
                                ? Theme.foreground
                                : Theme.hexToRgba(Theme.foreground, 0.7)
                            Behavior on color {
                                ColorAnimation { duration: 100 }
                            }
                        }
                    }

                    TapHandler {
                        onTapped: {
                            popup.close()
                            const proc = Qt.createQmlObject(
                                'import Quickshell.Io; Process { command: ' +
                                JSON.stringify(action.cmd) +
                                '; running: true }',
                                popup
                            )
                        }
                    }
                }
            }
        }
    }
}
