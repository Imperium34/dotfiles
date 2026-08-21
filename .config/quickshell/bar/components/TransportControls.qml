import qs
import qs.services
import QtQuick
import QtQuick.Layouts

// Prev / play-pause / next, driven entirely by MprisState.
// Shared by MediaPopup (mini player), Lock Screen and MusicLibraryPopup's Now tab.
RowLayout {
    id: root

    property int buttonSize: 40
    property int iconSize: 20
    property int playIconSize: 18

    spacing: 20

    Text {
        text: "󰒮"
        color: MprisState.canGoPrevious
            ? Theme.foreground
            : Theme.hexToRgba(Theme.foreground, 0.3)
        font.pixelSize: root.iconSize
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
        Layout.preferredWidth: root.buttonSize
        Layout.preferredHeight: root.buttonSize
        Layout.alignment: Qt.AlignVCenter
        radius: root.buttonSize / 2
        color: Theme.color5
        border.color: Theme.hexToRgba(Theme.foreground, 0.15)
        border.width: 1

        scale: playTap.pressed ? 0.9 : 1
        Behavior on scale {
            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
        }

        Text {
            anchors.centerIn: parent
            // the play glyph sits visually left of centre, nudge it back
            anchors.horizontalCenterOffset: MprisState.isPlaying ? 0 : 1
            text: MprisState.isPlaying ? "󰏤" : "󰐊"
            color: Theme.background
            font.pixelSize: root.playIconSize
            font.family: "Symbols Nerd Font"
        }

        TapHandler {
            id: playTap
            onTapped: MprisState.togglePlaying()
        }
    }

    Text {
        text: "󰒭"
        color: MprisState.canGoNext
            ? Theme.foreground
            : Theme.hexToRgba(Theme.foreground, 0.3)
        font.pixelSize: root.iconSize
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

