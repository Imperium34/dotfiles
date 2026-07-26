pragma Singleton

import Quickshell

Singleton {
    id: root

    property var active: null

    property bool expanded: false
    property real targetWidth: 0

    property real growSpeed: 2500

    function expand(popup) {
        if (root.active && root.active !== popup) {
            root.active.close()
        }
        root.active = popup
        root.targetWidth = popup.implicitWidth
        root.expanded = true
    }

    function collapse(popup) {
        if (root.active === popup) root.expanded = false
    }

    function notifyClosed(popup) {
        if (root.active === popup) root.active = null
    }
}
