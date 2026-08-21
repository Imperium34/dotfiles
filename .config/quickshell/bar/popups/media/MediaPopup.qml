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

    // ── BLURRED ART BACKDROP ───────────────────────────────────
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

    // ── CONTENT ────────────────────────────────────────────────
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

            TransportControls {
                Layout.alignment: Qt.AlignHCenter
            }

            SeekBar {
                Layout.fillWidth: true
            }
        }
    }
}

