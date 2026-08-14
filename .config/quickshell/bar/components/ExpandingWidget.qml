import qs
import QtQuick

Item {
    id: root

    property string icon: ""
    property string label: ""
    property color iconColor: Theme.foreground
    property int fontSize: 15

    implicitWidth: Math.max(iconText.implicitWidth, labelText.implicitWidth)
    implicitHeight: iconText.implicitHeight + 8

    HoverHandler {
        id: internalHover
    }

    property bool hovered: internalHover.hovered

    Text {
        id: iconText
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.icon
        color: root.iconColor
        font.pixelSize: root.fontSize

        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: hovered ? -8 : 0
        opacity: hovered ? 0 : 1

        Behavior on anchors.verticalCenterOffset {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }
    }

    Text {
        id: labelText
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.label
        color: root.iconColor
        font.pixelSize: root.fontSize - 2

        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: hovered ? 0 : 8
        opacity: hovered ? 1 : 0

        Behavior on anchors.verticalCenterOffset {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }
    }
}
