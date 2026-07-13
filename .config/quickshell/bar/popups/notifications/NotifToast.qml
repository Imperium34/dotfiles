import qs
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: root

    anchors.top: true
    anchors.right: true
    margins.top: 60
    margins.right: 12

    implicitWidth: 360
    implicitHeight: card.implicitHeight
    color: "transparent"

    exclusionMode: ExclusionMode.Ignore

    mask: Region {
        item: NotifService.toastVisible ? card : null
    }

    WlrLayershell.namespace: "quickshell:toast"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Rectangle {
        id: card
        width: parent.width
        implicitHeight: contentCol.implicitHeight + 24
        radius: 14
        color: Theme.hexToRgba(Theme.background, 0.92)
        border.color: {
            if (!NotifService.toastNotification) return Theme.hexToRgba(Theme.foreground, 0.1)
            return NotifService.toastNotification.urgency === NotificationUrgency.Critical
                ? Theme.hexToRgba(Theme.color1, 0.8)
                : Theme.hexToRgba(Theme.foreground, 0.1)
        }
        border.width: 1

        opacity: NotifService.toastVisible ? 1 : 0
        transformOrigin: Item.Top
        scale: NotifService.toastVisible ? 1 : 0.95

        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        ColumnLayout {
            id: contentCol
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 12
            }
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Image {
                    width: 16
                    height: 16
                    source: NotifService.toastNotification
                        ? Quickshell.iconPath(NotifService.toastNotification.appIcon, 32)
                        : ""
                    visible: source !== ""
                    fillMode: Image.PreserveAspectFit
                }

                Text {
                    text: NotifService.toastNotification
                        ? NotifService.toastNotification.appName
                        : ""
                    color: Theme.hexToRgba(Theme.foreground, 0.5)
                    font.pixelSize: 11
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Text {
                    text: "󰅖"
                    color: Theme.hexToRgba(Theme.foreground, 0.4)
                    font.pixelSize: 12
                    font.family: "Symbols Nerd Font"
                    TapHandler {
                        onTapped: NotifService.dismissToast()
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: NotifService.toastNotification
                    ? NotifService.toastNotification.summary
                    : ""
                color: Theme.foreground
                font.pixelSize: 13
                font.bold: true
                elide: Text.ElideRight
                visible: text !== ""
            }

            Text {
                Layout.fillWidth: true
                text: NotifService.toastNotification
                    ? NotifService.toastNotification.body
                    : ""
                color: Theme.hexToRgba(Theme.foreground, 0.75)
                font.pixelSize: 12
                wrapMode: Text.WordWrap
                maximumLineCount: 3
                elide: Text.ElideRight
                textFormat: Text.PlainText
                visible: text !== ""
            }
        }

        TapHandler {
            onTapped: NotifService.dismissToast()
        }
    }
}
