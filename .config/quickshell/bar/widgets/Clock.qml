import Quickshell
import QtQuick
import qs

Item {
    implicitWidth: clockText.implicitWidth
    implicitHeight: clockText.implicitHeight

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
}
