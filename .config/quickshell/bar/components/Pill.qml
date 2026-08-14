import qs
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property int padding: 20
    property alias spacing: row.spacing
    property alias contentOpacity: row.opacity
    default property alias content: row.data

    implicitHeight: 44
    implicitWidth: row.implicitWidth + padding * 2
    radius: height / 2
    color: Theme.hexToRgba(Theme.background, Theme.surfaceAlpha(0.85))
    border.color: Theme.hexToRgba(Theme.foreground, 0.1)
    border.width: 1

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 12
    }
}
