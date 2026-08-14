import qs
import qs.widgets
import qs.services
import qs.components
import Quickshell
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts

BasePopup {
    id: popup

    implicitWidth: 560
    implicitHeight: 205

    roundedMask: true

    Binding {
        target: MprisState
        property: "positionPolling"
        value: popup.visible
    }

    Image {
        id: artSource
        anchors.fill: parent
        source: MprisState.hasArt ? MprisState.trackArtUrl : ""
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: 560
        cache: true
        asynchronous: true
        visible: false
    }

    MultiEffect {
        id: artBlur
        anchors.fill: parent
        source: artSource
        visible: MprisState.hasArt
        blurEnabled: true
        blur: 1.0
        blurMax: 32
        brightness: -0.15
        saturation: 0.05
        transformOrigin: Item.Center

        SequentialAnimation on scale {
            running: MprisState.hasArt && popup.animIn
            loops: Animation.Infinite
            NumberAnimation {
                from: 1.0; to: 1.08
                duration: 20000
                easing.type: Easing.InOutSine
            }
            NumberAnimation {
                from: 1.08; to: 1.0
                duration: 20000
                easing.type: Easing.InOutSine
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.hexToRgba(Theme.background, 0.55) }
            GradientStop { position: 1.0; color: Theme.hexToRgba(Theme.background, 0.82) }
        }
    }

    RowLayout {
        anchors {
            fill: parent
            margins: 16
        }
        spacing: 16

        Rectangle {
            Layout.preferredWidth: 140
            Layout.preferredHeight: 140
            radius: 8
            color: Theme.hexToRgba(Theme.foreground, 0.05)
            clip: true

            Image {
                anchors.fill: parent
                source: MprisState.hasArt ? MprisState.trackArtUrl : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: MprisState.hasArt
            }

            Text {
                anchors.centerIn: parent
                text: "󰎆"
                color: Theme.foreground
                font.pixelSize: 40
                visible: !MprisState.hasArt
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                Layout.fillWidth: true
                text: MprisState.hasPlayer ? (MprisState.trackTitle || "Unknown Title") : ""
                color: Theme.foreground
                font.pixelSize: 15
                font.bold: true
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: MprisState.hasPlayer ? (MprisState.trackArtist || "Unknown Artist") : ""
                color: Theme.hexToRgba(Theme.foreground, 0.6)
                font.pixelSize: 12
                elide: Text.ElideRight
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 20

                Text {
                    id: prevBtn
                    text: "󰒮"
                    color: MprisState.canGoPrevious
                        ? Theme.foreground
                        : Theme.hexToRgba(Theme.foreground, 0.3)
                    font.pixelSize: 20
                    font.family: "Symbols Nerd Font"
                    Layout.alignment: Qt.AlignVCenter

                    scale: prevTap.pressed ? 0.85 : 1
                    Behavior on scale {
                        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                    }

                    TapHandler {
                        id: prevTap
                        onTapped: MprisState.previous()
                    }
                }

                Rectangle {
                    id: playButton
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    radius: 20
                    color: Theme.color5
                    border.color: Theme.hexToRgba(Theme.foreground, 0.15)
                    border.width: 1
                    Layout.alignment: Qt.AlignVCenter

                    scale: playTap.pressed ? 0.9 : 1
                    Behavior on scale {
                        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                    }

                    Text {
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: MprisState.isPlaying ? 0 : 1
                        text: MprisState.isPlaying ? "󰏤" : "󰐊"
                        color: Theme.background
                        font.pixelSize: 18
                        font.family: "Symbols Nerd Font"
                    }

                    TapHandler {
                        id: playTap
                        onTapped: MprisState.togglePlaying()
                    }
                }

                Text {
                    id: nextBtn
                    text: "󰒭"
                    color: MprisState.canGoNext
                        ? Theme.foreground
                        : Theme.hexToRgba(Theme.foreground, 0.3)
                    font.pixelSize: 20
                    font.family: "Symbols Nerd Font"
                    Layout.alignment: Qt.AlignVCenter

                    scale: nextTap.pressed ? 0.85 : 1
                    Behavior on scale {
                        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                    }

                    TapHandler {
                        id: nextTap
                        onTapped: MprisState.next()
                    }
                }
            }

            ColumnLayout {
                id: seekCol
                Layout.fillWidth: true
                spacing: 4

                Item {
                    id: seekArea
                    Layout.fillWidth: true
                    Layout.preferredHeight: 20

                    Rectangle {
                        anchors {
                            left: parent.left
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                        }
                        height: 4
                        radius: 2
                        color: Theme.hexToRgba(Theme.foreground, 0.15)

                        Rectangle {
                            width: parent.width * MprisState.progress
                            height: parent.height
                            radius: 2
                            color: Theme.color5
                            Behavior on width {
                                NumberAnimation { duration: 200 }
                            }
                        }
                    }

                    TapHandler {
                        onTapped: (eventPoint) => {
                            MprisState.seekToRatio(eventPoint.position.x / seekArea.width)
                        }
                    }

                    DragHandler {
                        target: null
                        yAxis.enabled: false
                        onCentroidChanged: {
                            if (active)
                                MprisState.seekToRatio(centroid.position.x / seekArea.width)
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: MprisState.formatTime(MprisState.position)
                        color: Theme.hexToRgba(Theme.foreground, 0.6)
                        font.pixelSize: 11
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: MprisState.formatTime(MprisState.length)
                        color: Theme.hexToRgba(Theme.foreground, 0.6)
                        font.pixelSize: 11
                    }
                }
            }
        }
    }
}
