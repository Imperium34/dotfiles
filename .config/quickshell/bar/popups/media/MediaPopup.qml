import "../../widgets"
import qs
import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts

BasePopup {
    id: popup
    required property var player

    implicitWidth: 560
    implicitHeight: 205

    readonly property bool hasArt: player
        && player.trackArtUrl
        && player.trackArtUrl !== ""

    Rectangle {
        id: card
        anchors.fill: parent
        radius: 16
        color: Theme.hexToRgba(Theme.background, 0.92)
        border.color: Theme.hexToRgba(Theme.foreground, 0.1)
        border.width: 1
        antialiasing: true

        opacity: popup.animIn ? 1 : 0
        scale: popup.animIn ? 1 : 0.95
        transformOrigin: Item.Top

        Behavior on opacity {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }

        layer.enabled: true
        layer.smooth: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: cornerMask
        }

        Image {
            id: artSource
            anchors.fill: parent
            source: popup.hasArt ? player.trackArtUrl : ""
            fillMode: Image.PreserveAspectCrop
            cache: false
            asynchronous: true
            visible: false
        }

        MultiEffect {
            id: artBlur
            anchors.fill: parent
            source: artSource
            visible: popup.hasArt
            blurEnabled: true
            blur: 1.0
            blurMax: 48
            brightness: -0.15
            saturation: 0.05
            transformOrigin: Item.Center

            SequentialAnimation on scale {
                running: popup.hasArt && popup.animIn
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
                width: 140
                height: 140
                radius: 8
                color: Theme.hexToRgba(Theme.foreground, 0.05)
                clip: true

                Image {
                    anchors.fill: parent
                    source: popup.hasArt ? player.trackArtUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: popup.hasArt
                }

                Text {
                    anchors.centerIn: parent
                    text: "󰎆"
                    color: Theme.foreground
                    font.pixelSize: 40
                    visible: !popup.hasArt
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: player ? (player.trackTitle || "Unknown Title") : ""
                    color: Theme.foreground
                    font.pixelSize: 15
                    font.bold: true
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: player ? (player.trackArtist || "Unknown Artist") : ""
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
                        color: player && player.canGoPrevious
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
                            onTapped: if (player && player.canGoPrevious) player.previous()
                        }
                    }

                    Rectangle {
                        id: playButton
                        width: 40
                        height: 40
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
                            anchors.horizontalCenterOffset: player && player.isPlaying ? 0 : 1
                            text: player && player.isPlaying ? "󰏤" : "󰐊"
                            color: Theme.background
                            font.pixelSize: 18
                            font.family: "Symbols Nerd Font"
                        }

                        TapHandler {
                            id: playTap
                            onTapped: if (player && player.canTogglePlaying) player.togglePlaying()
                        }
                    }

                    Text {
                        id: nextBtn
                        text: "󰒭"
                        color: player && player.canGoNext
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
                            onTapped: if (player && player.canGoNext) player.next()
                        }
                    }
                }

                ColumnLayout {
                    id: seekCol
                    Layout.fillWidth: true
                    spacing: 4

                    property real position: player ? player.position : 0

                    Timer {
                        interval: 1000
                        running: player && player.isPlaying && popup.visible
                        repeat: true
                        onTriggered: seekCol.position = player ? player.position : 0
                    }

                    Item {
                        id: seekArea
                        Layout.fillWidth: true
                        height: 20

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
                                width: player && player.length > 0
                                    ? parent.width * (seekCol.position / player.length) : 0
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
                                if (!player || !player.canSeek) return
                                player.position = (eventPoint.position.x / seekArea.width) * player.length
                            }
                        }

                        DragHandler {
                            target: null
                            yAxis.enabled: false
                            onCentroidChanged: {
                                if (active && player && player.canSeek) {
                                    const ratio = Math.max(0, Math.min(1,
                                        centroid.position.x / seekArea.width))
                                    player.position = ratio * player.length
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: formatTime(seekCol.position)
                            color: Theme.hexToRgba(Theme.foreground, 0.6)
                            font.pixelSize: 11
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: player ? formatTime(player.length) : "0:00"
                            color: Theme.hexToRgba(Theme.foreground, 0.6)
                            font.pixelSize: 11
                        }
                    }
                }
            }
        }
    }

    Item {
        id: cornerMask
        anchors.fill: card
        layer.enabled: true
        visible: false
        Rectangle {
            anchors.fill: parent
            radius: card.radius
            color: "black"
        }
    }

    function formatTime(seconds) {
        const m = Math.floor(seconds / 60)
        const s = Math.floor(seconds % 60)
        return m + ":" + (s < 10 ? "0" + s : s)
    }
}

