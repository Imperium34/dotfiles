import "popups/notifications"
import Quickshell
import QtQuick

Scope {
    Bar {}
    OSD {}
    NotifToast {}
    PowerActions {}
    Component.onCompleted: BatteryAlert.lowThreshold
}
