pragma Singleton

import Quickshell
import Quickshell.Wayland

Singleton {
    id: root

    property bool inhibiting: false

    // window must be set externally from Bar.qml after the PanelWindow exists
    property var window: null

    IdleInhibitor {
        window: root.window
        enabled: root.inhibiting
    }
}
