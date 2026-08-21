import qs
import qs.services
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root
    spacing: 4

    Item {
        id: seekArea
        Layout.fillWidth: true
        Layout.preferredHeight: 20

        Rectangle {
            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
            height: 4
            radius: 2
            color: Theme.hexToRgba(Theme.foreground, 0.15)

            Rectangle {
                width: parent.width * MprisState.progress
                height: parent.height
                radius: 2
                color: Theme.color5
                Behavior on width { NumberAnimation { duration: 200 } }
            }
        }

        TapHandler {
            onTapped: (eventPoint) => MprisState.seekToRatio(eventPoint.position.x / seekArea.width)
        }
        DragHandler {
            target: null
            yAxis.enabled: false
            onCentroidChanged: if (active) MprisState.seekToRatio(centroid.position.x / seekArea.width)
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Text { text: MprisState.formatTime(MprisState.position); color: Theme.hexToRgba(Theme.foreground, 0.6); font.pixelSize: 11 }
        Item { Layout.fillWidth: true }
        Text { text: MprisState.formatTime(MprisState.length); color: Theme.hexToRgba(Theme.foreground, 0.6); font.pixelSize: 11 }
    }
}
