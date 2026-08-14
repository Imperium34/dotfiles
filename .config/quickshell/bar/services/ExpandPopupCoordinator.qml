pragma Singleton

import Quickshell

Singleton {
    id: root

    property var active: null

    property var activeBar: null

    property bool expanded: false
    property real targetWidth: 0

    property real previousWidth: 0

    property real growSpeed: 2500

    function expand(popup, bar) {
        root.previousWidth = root.expanded ? root.targetWidth : popup.originWidth

        if (root.active && root.active !== popup) {
            root.active.close()
        }

        root.active = popup
        root.activeBar = bar
        root.targetWidth = popup.implicitWidth
        root.expanded = true

        return root.previousWidth
    }

    function collapse(popup) {
        if (root.active === popup) root.expanded = false
    }

    function notifyClosed(popup) {
        if (root.active === popup) {
            root.active = null
            root.activeBar = null
        }
    }
}
