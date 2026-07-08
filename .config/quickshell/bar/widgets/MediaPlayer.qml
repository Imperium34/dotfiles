import "../popups/media"
import qs
import qs.widgets
import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts

BarButton {
    id: root

    readonly property var player: Mpris.players.values.length > 0
        ? Mpris.players.values[0] : null

    readonly property bool hasPlayer: player !== null
    readonly property bool isPlaying: hasPlayer && player.isPlaying

    visible: hasPlayer
    implicitWidth: hasPlayer ? innerRow.implicitWidth + 16 : 0
    implicitHeight: hasPlayer ? innerRow.implicitHeight + 8 : 0

    Behavior on implicitWidth {
        NumberAnimation { duration: 200; easing.type: Easing.InOutQuart }
    }

    popup: MediaPopup { player: root.player }

    onVisibleChanged: if (!visible && popup) popup.visible = false

    RowLayout {
        id: innerRow
        anchors.centerIn: parent
        spacing: 8

        Row {
            spacing: 2
            visible: isPlaying

            Repeater {
                model: 3
                Rectangle {
                    width: 3
                    height: 8
                    radius: 1
                    color: Theme.color5

                    SequentialAnimation on height {
                        running: isPlaying
                        loops: Animation.Infinite
                        NumberAnimation {
                            to: 14
                            duration: 400 + index * 100
                            easing.type: Easing.InOutSine
                        }
                        NumberAnimation {
                            to: 4
                            duration: 400 + index * 100
                            easing.type: Easing.InOutSine
                        }
                    }
                }
            }
        }

        Text {
            visible: hasPlayer && !isPlaying
            text: ""
            color: Theme.foreground
            font.pixelSize: 12
        }

        Item {
            width: 120
            height: titleText.implicitHeight
            clip: true

            Text {
                id: titleText
                text: hasPlayer ? (player.trackTitle || "Unknown") : ""
                color: Theme.foreground
                font.pixelSize: 13

                NumberAnimation on x {
                    running: isPlaying && titleText.implicitWidth > 120
                    from: 0
                    to: titleText.implicitWidth > 100 ? -(titleText.implicitWidth - 100) : 0
                    duration: Math.max(0, (titleText.implicitWidth - 100) * 30)
                    loops: Animation.Infinite
                    easing.type: Easing.Linear
                }
            }
        }
    }
}
