pragma Singleton

import Quickshell

Singleton {
    id: root

    property var active: null

    property var activeBar: null

    property bool expanded: false
    property real targetWidth: 0

    property real growSpeed: 2500
    property real growDuration: 0

    property var pendingPopup: null
    property var pendingBar: null

    function durationFor(fromWidth, toWidth) {
        return Math.round(Math.abs(toWidth - fromWidth) / root.growSpeed * 1000)
    }

    function _beginExpand(popup, bar) {
        const from = (bar && bar.pillCurrentWidth > 0)
            ? bar.pillCurrentWidth
            : popup.originWidth

        root.growDuration = root.durationFor(from, popup.implicitWidth)

        root.active = popup
        root.activeBar = bar
        root.targetWidth = popup.implicitWidth
        root.expanded = true

        return root.growDuration
    }

    function expand(popup, bar) {
        if (root.pendingPopup && root.pendingPopup !== popup) {
            root.pendingPopup.abortOpen()
            root.pendingPopup = null
            root.pendingBar = null
        }

        if (root.active && root.active !== popup) {
            root.pendingPopup = popup
            root.pendingBar = bar
            root.active.close(true)
            return -1
        }

        return root._beginExpand(popup, bar)
    }

    function collapse(popup) {
        if (root.active !== popup) return

        if (root.pendingPopup) {
            const p = root.pendingPopup
            const b = root.pendingBar
            root.pendingPopup = null
            root.pendingBar = null
            p.startExpandPhase(root._beginExpand(p, b))
            return
        }

        const bar = root.activeBar
        const from = (bar && bar.pillCurrentWidth > 0) ? bar.pillCurrentWidth : root.targetWidth
        const to = (bar && bar.pillWidth > 0) ? bar.pillWidth : popup.originWidth

        root.growDuration = root.durationFor(from, to)
        root.expanded = false
    }

    function notifyClosed(popup) {
        if (root.active === popup) {
            root.active = null
            root.activeBar = null
        }
    }
}
