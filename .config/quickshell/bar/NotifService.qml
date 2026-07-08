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

            if (root.toastNotification.urgency === NotificationUrgency.Critical) return 10000

            const t = root.toastNotification.expireTimeout
            if (t <= 0) return 5000
            return Math.max(t * 1000, 3000)
        }
        onTriggered: root.toastVisible = false
    }

    function dismissToast() {
        toastTimer.stop()
        toastVisible = false
    }

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
