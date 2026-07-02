pragma Singleton

import qs
import Quickshell
import Quickshell.Services.Notifications
import QtQuick

Singleton {
    id: root

    property bool dnd: false

    readonly property var server: NotificationServer {
        actionsSupported: false
        bodySupported: true
        imageSupported: true
        keepOnReload: true

        onNotification: (notif) => {
            if (notif.transient) {
                notif.tracked = false
                root.toastNotification = notif
                root.toastVisible = true
                toastTimer.stop()
                toastTimer.start()

            } else {
                notif.tracked = true
                if (!root.dnd) {
                    root.toastNotification = notif
                    root.toastVisible = true
                    toastTimer.stop()
                    toastTimer.start()
                }
            }
        }
    }

    property var toastNotification: null
    property bool toastVisible: false

    Timer {
        id: toastTimer
        interval: {
            if (!root.toastNotification) return 5000

            // Critical first: a Critical notification should get 10s regardless
            // of its expireTimeout (incl. 0 or -1). Checking urgency AFTER the
            // timeout branches let a Critical with expireTimeout 0 fall through
            // to 5000 — the bug this reordering fixes.
            if (root.toastNotification.urgency === NotificationUrgency.Critical) return 10000

            const t = root.toastNotification.expireTimeout
            if (t <= 0) return 5000   // -1 = use default, 0 = never-expire → cap at default
            return Math.max(t * 1000, 3000)
        }
        onTriggered: root.toastVisible = false
    }

    function dismissToast() {
        toastTimer.stop()
        toastVisible = false
    }

    // server.trackedNotifications is an ObjectModel; .values and .values.length
    // are membership-reactive, which is exactly when count changes (add/remove).
    // No _count proxy needed — this was already correct.
    readonly property var notifications: server.trackedNotifications
    readonly property int count: server.trackedNotifications.values.length

    function dismissAll() {
        const notifs = server.trackedNotifications.values.slice()
        for (const n of notifs) n.dismiss()
    }

    function toggleDnd() {
        dnd = !dnd
        if (dnd) dismissToast()
    }
}
