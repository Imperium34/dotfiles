import qs
import QtQuick

Item {
    id: root

    property string icon: ""
    property real value: 0.0
    property color iconColor: Theme.foreground
    property int fontSize: 15

    signal sliderMoved(real newValue)

    readonly property bool expanded: hover.hovered
    readonly property real collapsedWidth: fontSize + 8
    readonly property real expandedWidth: collapsedWidth + 120

    implicitHeight: 28
    implicitWidth: expanded ? expandedWidth : collapsedWidth

    Behavior on implicitWidth {
        NumberAnimation {
            duration: 200
            easing.type: Easing.InOutQuart
        }
    }

    HoverHandler {
        id: hover
    }

    Item {
        id: iconContainer
        x: 0
        width: root.fontSize + 8
        height: parent.height
        anchors.verticalCenter: parent.verticalCenter

        Text {
            id: iconText
            anchors.centerIn: parent
            text: root.icon
            color: root.iconColor
            font.pixelSize: root.fontSize
        }
    }

    Item {
        id: trackContainer
        x: iconContainer.x + iconContainer.width + 8
        width: root.implicitWidth - x - 4
        height: 20
        anchors.verticalCenter: parent.verticalCenter
        opacity: expanded ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: 150 }
        }

        Rectangle {
            anchors.fill: parent
            radius: 10
            color: Theme.hexToRgba(Theme.foreground, 0.15)
        }

        Rectangle {
            width: parent.width * root.value
            height: parent.height
            radius: 10
            color: root.iconColor

            Behavior on width {
                NumberAnimation { duration: 50 }
            }
        }

        TapHandler {
            onTapped: (eventPoint) => {
                const newVal = Math.max(0, Math.min(1, eventPoint.position.x / trackContainer.width))
                root.sliderMoved(newVal)
            }
        }

        DragHandler {
            id: drag
            target: null
            yAxis.enabled: false
            onActiveChanged: {
                if (active) {
                    const pos = drag.centroid.position.x
                    const newVal = Math.max(0, Math.min(1, pos / trackContainer.width))
                    root.sliderMoved(newVal)
                }
            }
            onCentroidChanged: {
                if (active) {
                    const pos = drag.centroid.position.x
                    const newVal = Math.max(0, Math.min(1, pos / trackContainer.width))
                    root.sliderMoved(newVal)
                }
            }
        }
    }

    WheelHandler {
        target: null
        onWheel: (event) => {
            const delta = event.angleDelta.y > 0 ? 0.02 : -0.02
            const newVal = Math.max(0, Math.min(1, root.value + delta))
            root.sliderMoved(Math.round(newVal * 100) / 100)
        }
    }
}
