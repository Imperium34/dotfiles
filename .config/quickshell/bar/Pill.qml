import qs
import QtQuick
import QtQuick.Layouts

// The frosted bar container. Was copy-pasted three times in Bar.qml; now one
// component. Positioning (left/center/right anchors) stays in Bar.qml -- this is
// just the pill shell + its horizontal content row.
Rectangle {
    id: root

    property int padding: 20
    property alias spacing: row.spacing
    default property alias content: row.data

    implicitHeight: 44
    implicitWidth: row.implicitWidth + padding * 2
    radius: height / 2
    color: Theme.hexToRgba(Theme.background, 0.85)
    border.color: Theme.hexToRgba(Theme.foreground, 0.1)
    border.width: 1

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 12
    }
}
