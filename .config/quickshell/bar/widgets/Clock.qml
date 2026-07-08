import qs
import qs.widgets
import Quickshell
import QtQuick
import "../popups/calendar"

BarButton {
    id: root

    implicitWidth: clockText.implicitWidth + 8
    implicitHeight: clockText.implicitHeight + 8

    popup: CalendarPopup {}

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: clockHover.hovered ? Theme.hexToRgba(Theme.foreground, 0.08) : "transparent"
        z: -1
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    HoverHandler { id: clockHover }

    Text {
        id: clockText
        anchors.centerIn: parent
        text: Qt.formatDateTime(clock.date, "HH:mm")
        color: Theme.foreground
        font.pixelSize: 15
    }
}
