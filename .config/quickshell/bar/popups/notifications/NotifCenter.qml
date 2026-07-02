import "../../widgets"
import qs
import Quickshell
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts

BasePopup {
    id: popup
    implicitWidth: 380
    implicitHeight: Math.min(
        header.height + notifList.height + footer.height,
        600
    )

    readonly property var notifModel: {
        const _dep = NotifService.count
        return NotifService.notifications.values.slice().reverse()
    }

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
                text: "Notifications"
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
                    color: NotifService.dnd
                        ? Theme.color1
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
                    x: NotifService.dnd ? parent.width - width - 3 : 3

                    Behavior on x {
                        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                    }
                }

                TapHandler {
                    onTapped: NotifService.toggleDnd()
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
            id: notifList
            anchors.top: headerDivider.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: Math.min(contentHeight, 480)
            clip: true
            model: notifModel
            interactive: contentHeight > height

            Text {
                anchors.centerIn: parent
                text: NotifService.dnd ? "Do not disturb" : "No notifications"
                color: Theme.hexToRgba(Theme.foreground, 0.4)
                font.pixelSize: 13
                visible: notifList.count === 0
                topPadding: 24
                bottomPadding: 24
            }

            delegate: Item {
                width: notifList.width
                height: notifCard.height + 6

                readonly property var notif: notifModel[index]

                NotifCard {
                    id: notifCard
                    width: parent.width - 12
                    anchors.horizontalCenter: parent.horizontalCenter
                    notification: parent.notif
                }
            }
        }

        Rectangle {
            id: footer
            anchors.top: notifList.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: NotifService.count > 0 ? 44 : 0
            visible: height > 0
            color: "transparent"

            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                height: 1
                color: Theme.hexToRgba(Theme.foreground, 0.08)
                visible: NotifService.count > 0
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

            Text {
                anchors.centerIn: parent
                text: "Clear all"
                color: Theme.hexToRgba(Theme.foreground, 0.6)
                font.pixelSize: 13
                visible: NotifService.count > 0
            }

            TapHandler {
                onTapped: NotifService.dismissAll()
            }
        }
    }
}
