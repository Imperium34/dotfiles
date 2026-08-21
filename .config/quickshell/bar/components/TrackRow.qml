import qs
import QtQuick
import QtQuick.Layouts

// Generic row for SelectableListView: optional thumbnail, two lines of text,
// optional trailing label. Used for search results, playlists, playlist
// tracks and queue entries so those delegates stay one-liners.
RowLayout {
    id: root

    property var modelData: null
    property int index: 0
    property bool selected: false

    // ---- content ----
    property string overlineText: ""
    property string primaryText: ""
    property string secondaryText: ""
    property string trailingText: ""
    property string thumbnailSource: ""

    // ---- layout ----
    property bool showThumbnail: true
    property int thumbnailSize: 40
    property int sideMargin: 10

    signal activated()

    anchors {
        fill: parent
        leftMargin: root.sideMargin
        rightMargin: root.sideMargin
    }
    spacing: 10

    Rectangle {
        visible: root.showThumbnail
        Layout.preferredWidth: root.thumbnailSize
        Layout.preferredHeight: root.thumbnailSize
        Layout.alignment: Qt.AlignVCenter
        radius: 6
        color: Theme.hexToRgba(Theme.foreground, 0.06)
        clip: true

        Image {
            anchors.fill: parent
            source: root.thumbnailSource
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: root.thumbnailSize * 2
            sourceSize.height: root.thumbnailSize * 2
            visible: root.thumbnailSource !== ""
        }

        Text {
            anchors.centerIn: parent
            text: "󰎆"
            color: Theme.hexToRgba(Theme.foreground, 0.4)
            font.pixelSize: Math.round(root.thumbnailSize * 0.4)
            font.family: "Symbols Nerd Font"
            visible: root.thumbnailSource === ""
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        Text {
            visible: root.overlineText !== ""
            text: root.overlineText
            color: Theme.hexToRgba(Theme.color5, 0.9)
            font.pixelSize: 10
            font.family: "Symbols Nerd Font"
        }

        Text {
            Layout.fillWidth: true
            text: root.primaryText
            color: root.selected ? Theme.background : Theme.foreground
            font.pixelSize: 13
            font.bold: root.selected
            elide: Text.ElideRight
        }

        Text {
            Layout.fillWidth: true
            visible: root.secondaryText !== ""
            text: root.secondaryText
            color: root.selected
                ? Theme.hexToRgba(Theme.background, 0.7)
                : Theme.hexToRgba(Theme.foreground, 0.55)
            font.pixelSize: 11
            elide: Text.ElideRight
        }
    }

    Text {
        visible: root.trailingText !== ""
        text: root.trailingText
        color: root.selected
            ? Theme.hexToRgba(Theme.background, 0.7)
            : Theme.hexToRgba(Theme.foreground, 0.5)
        font.pixelSize: 11
        Layout.alignment: Qt.AlignVCenter
    }

    TapHandler {
        onTapped: root.activated()
    }
}

