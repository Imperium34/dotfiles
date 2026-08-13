import "popups/notifications"
import Quickshell
import QtQuick
import qs.services

Scope {
    Bar {}
    OSD {}
    NotifToast {}
    PowerActions {}
    Component.onCompleted: BatteryAlert.lowThreshold
}
