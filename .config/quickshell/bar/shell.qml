import Quickshell
import QtQuick
import qs.windows
import qs.services
import qs.components
import qs.popups.notifications

Scope {
    Bar {}
    OSD {}
    NotifToast {}
    PowerActions {}
    Component.onCompleted: BatteryAlert.lowThreshold
}
