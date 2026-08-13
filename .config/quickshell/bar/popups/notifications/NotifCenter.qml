import qs
import qs.services
import qs.widgets
import Quickshell
import Quickshell.Services.Notifications
import QtQuick

ToggleListPopup {
    id: popup

    implicitWidth: 380
    title: "Notifications"

    toggleOn: NotifService.dnd
    toggleOnColor: Theme.color1
    onToggled: NotifService.toggleDnd()

    model: notifModel
    maxListHeight: 480
    maxPopupHeight: 600

    emptyText: NotifService.dnd ? "Do not disturb" : "No notifications"

    footerText: "Clear all"
    footerVisible: NotifService.count > 0
    onFooterActivated: NotifService.dismissAll()

    readonly property var notifModel: {
        const _dep = NotifService.count
        return NotifService.notifications.values.slice().reverse()
    }

    rowDelegate: Component {
        Item {
            required property int index
            width: ListView.view.width
            height: notifCard.height + 6
            readonly property var notif: popup.notifModel[index]

            NotifCard {
                id: notifCard
                width: parent.width - 12
                anchors.horizontalCenter: parent.horizontalCenter
                notification: parent.notif
            }
        }
    }
}
