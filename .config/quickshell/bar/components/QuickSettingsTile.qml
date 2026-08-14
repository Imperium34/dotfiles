import qs
import QtQuick
import QtQuick.Layouts

// One toggle tile in the quick settings grid: icon, label, optional sublabel,
// and an on/off state. Tapping the body toggles; tapping the chevron (when
// hasDetail is set) opens the tile's detail pane.
Rectangle {
    id: root

    property string icon: ""
    property string label: ""
    property string sublabel: ""
    property bool active: false
    property bool interactive: true

    property bool hasDetail: false
    readonly property int detailZoneWidth: 34

    signal activated()
    signal detailRequested()

    implicitHeight: 64
    radius: 12

    color: !root.interactive
        ? Theme.hexToRgba(Theme.foreground, 0.03)
        : root.active
            ? Theme.hexToRgba(Theme.color5, 0.22)
            : (tileHover.hovered
                ? Theme.hexToRgba(Theme.foreground, 0.09)
                : Theme.hexToRgba(Theme.foreground, 0.05))

    border.color: root.active
        ? Theme.hexToRgba(Theme.color5, 0.55)
        : "transparent"
    border.width: 1

    Behavior on color { ColorAnimation { duration: 120 } }
    Behavior on border.color { ColorAnimation { duration: 120 } }

    scale: tileTap.pressed ? 0.97 : 1
    Behavior on scale {
        NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
    }

    HoverHandler { id: tileHover }

    RowLayout {
        anchors {
            fill: parent
            leftMargin: 12
            rightMargin: root.hasDetail ? root.detailZoneWidth : 12
        }
        spacing: 10

        Text {
            text: root.icon
            font.pixelSize: 20
            font.family: "Symbols Nerd Font"
            color: !root.interactive
                ? Theme.hexToRgba(Theme.foreground, 0.25)
                : root.active ? Theme.color5 : Theme.hexToRgba(Theme.foreground, 0.75)
            Behavior on color { ColorAnimation { duration: 120 } }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Text {
                Layout.fillWidth: true
                text: root.label
                font.pixelSize: 12
                font.bold: true
                elide: Text.ElideRight
                color: !root.interactive
                    ? Theme.hexToRgba(Theme.foreground, 0.3)
                    : Theme.foreground
            }

            Text {
                Layout.fillWidth: true
                text: root.sublabel
                font.pixelSize: 10
                elide: Text.ElideRight
                visible: text !== ""
                color: Theme.hexToRgba(Theme.foreground, 0.5)
            }
        }
    }

    Text {
        visible: root.hasDetail
        anchors {
            right: parent.right
            rightMargin: 12
            verticalCenter: parent.verticalCenter
        }
        text: "󰅂"
        font.pixelSize: 14
        font.family: "Symbols Nerd Font"
        color: chevronHover.hovered
            ? Theme.foreground
            : Theme.hexToRgba(Theme.foreground, 0.4)
        Behavior on color { ColorAnimation { duration: 100 } }

        HoverHandler { id: chevronHover }
    }

    TapHandler {
        id: tileTap
        enabled: root.interactive
        onTapped: (eventPoint) => {
            if (root.hasDetail && eventPoint.position.x > root.width - root.detailZoneWidth) {
                root.detailRequested()
            } else {
                root.activated()
            }
        }
    }
}
