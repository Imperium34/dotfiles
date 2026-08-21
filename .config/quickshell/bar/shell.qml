import Quickshell
import Quickshell.Io
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
    Wallpaper {}
    Launcher {}
    Clipboard {}
    MusicLibraryPopup {}
    QuickSettings {}
    Keybinds {}

    LazyLoader {
        id: sysMonitorLoader
        component: SysMonitorWindow {
            visible: true
            onCloseRequested: sysMonitorLoader.activeAsync = false
        }
    }

    IpcHandler {
        target: "sysmonitor"
        function open(): void { sysMonitorLoader.activeAsync = true }
    }

    Binding {
        target: IdleInhibit
        property: "window"
        value: BarRegistry.focusedBar
    }

    Component.onCompleted: BatteryAlert.lowThreshold
}
