import qs
import Quickshell
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    required property var notification

    implicitHeight: inner.implicitHeight + 16

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: {
            if (!notification) return "transparent"
            if (notification.urgency === NotificationUrgency.Critical)
                return Theme.hexToRgba(Theme.color1, 0.08)
            return Theme.hexToRgba(Theme.foreground, 0.04)
        }
        border.color: {
            if (!notification) return "transparent"
            if (notification.urgency === NotificationUrgency.Critical)
                return Theme.hexToRgba(Theme.color1, 0.3)
            return Theme.hexToRgba(Theme.foreground, 0.08)
        }
        border.width: 1
    }

    ColumnLayout {
        id: inner
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: 10
        }
        spacing: 3

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Image {
                width: 14
                height: 14
                source: notification
                    ? Quickshell.iconPath(notification.appIcon, 32)
                    : ""
                visible: source !== ""
                fillMode: Image.PreserveAspectFit
            }

            Text {
                text: notification ? notification.appName : ""
                color: Theme.hexToRgba(Theme.foreground, 0.45)
                font.pixelSize: 11
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            Text {
                text: "󰅖"
                color: Theme.hexToRgba(Theme.foreground, 0.35)
                font.pixelSize: 11
                font.family: "Symbols Nerd Font"

                TapHandler {
                    onTapped: if (notification) notification.dismiss()
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: notification ? notification.summary : ""
            color: Theme.foreground
            font.pixelSize: 12
            font.bold: true
            elide: Text.ElideRight
            visible: text !== ""
        }

        Text {
            Layout.fillWidth: true
            text: notification ? notification.body : ""
            color: Theme.hexToRgba(Theme.foreground, 0.7)
            font.pixelSize: 11
            wrapMode: Text.WordWrap
            maximumLineCount: 4
            elide: Text.ElideRight
            textFormat: Text.PlainText
            visible: text !== ""
        }
    }
}
