import qs
import qs.widgets
import qs.services
import qs.components
import qs.popups.media
import Quickshell
import QtQuick
import QtQuick.Layouts

BarButton {
    id: root

    readonly property bool hasPlayer: MprisState.hasPlayer
    readonly property bool isPlaying: MprisState.isPlaying

    readonly property int marqueeWidth: 120

    visible: hasPlayer
    implicitWidth: hasPlayer ? innerRow.implicitWidth + 16 : 0
    implicitHeight: hasPlayer ? innerRow.implicitHeight + 8 : 0

    Behavior on implicitWidth {
        NumberAnimation { duration: 200; easing.type: Easing.InOutQuart }
    }

    popup: MediaPopup {}

    onVisibleChanged: if (!visible && popup) popup.visible = false

    RowLayout {
        id: innerRow
        anchors.centerIn: parent
        spacing: 8

        // Playing: animated equaliser bars.
        Row {
            spacing: 2
            visible: root.isPlaying

            Repeater {
                model: 3
                Rectangle {
                    width: 3
                    height: 8
                    radius: 1
                    color: Theme.color5

                    SequentialAnimation on height {
                        running: root.isPlaying
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
            visible: root.hasPlayer && !root.isPlaying
            text: "󰏤"
            color: Theme.foreground
            font.pixelSize: 12
            font.family: "Symbols Nerd Font"
        }

        Item {
            width: root.marqueeWidth
            height: titleText.implicitHeight
            clip: true

            Text {
                id: titleText
                text: root.hasPlayer ? (MprisState.trackTitle || "Unknown") : ""
                color: Theme.foreground
                font.pixelSize: 13

                readonly property real overflow: Math.max(0, titleText.implicitWidth - root.marqueeWidth)

                NumberAnimation on x {
                    running: root.isPlaying && titleText.overflow > 0
                    from: 0
                    to: -titleText.overflow
                    duration: Math.max(300, titleText.overflow * 30)
                    loops: Animation.Infinite
                    easing.type: Easing.Linear
                }
            }
        }
    }
}
