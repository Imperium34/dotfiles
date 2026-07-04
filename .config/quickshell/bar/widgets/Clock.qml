import Quickshell
import QtQuick
import qs
import "../popups/calendar"

Item {
    id: root
    implicitWidth: clockText.implicitWidth + 8
    implicitHeight: clockText.implicitHeight + 8

    required property var barWindow 

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Text {
        id: clockText
        anchors.centerIn: parent
        text: Qt.formatDateTime(clock.date, "HH:mm")
        color: Theme.foreground
        font.pixelSize: 15
    }

    HoverHandler { id: clockHover }
    
    Rectangle {
        anchors.fill: parent
        radius: 8
        color: clockHover.hovered ? Theme.hexToRgba(Theme.foreground, 0.08) : "transparent"
        z: -1
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    TapHandler {
        onTapped: calendarPopup.toggle()
    }

    CalendarPopup {
        id: calendarPopup
        barWindow: root.barWindow
        anchorX: ((root.barWindow.screen ? root.barWindow.screen.width : 1920) - implicitWidth) / 2
    }
}
