import qs
import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property var screen
    readonly property var hyprMonitor: Hyprland.monitorFor(screen)

    property bool thisMonitorOnly: false

    readonly property var sortedWorkspaces: {
        let ws = Hyprland.workspaces.values.filter(w => !w.name.startsWith("special:"))
        if (root.thisMonitorOnly && root.hyprMonitor)
            ws = ws.filter(w => w.monitor === root.hyprMonitor)
        ws.sort((a, b) => a.id - b.id)
        return ws
    }

    readonly property var activeWorkspace: {
        for (const ws of root.sortedWorkspaces) {
            if (ws.monitor === root.hyprMonitor && ws.active) return ws
        }
        return null
    }

    implicitWidth: wsRow.implicitWidth
    implicitHeight: wsRow.implicitHeight

    Rectangle {
        id: indicator
        y: 0
        height: parent.height
        radius: height / 2
        color: Theme.color4
        visible: root.activeWorkspace !== null

        Behavior on x {
            NumberAnimation { duration: 200; easing.type: Easing.InOutQuart }
        }
        Behavior on width {
            NumberAnimation { duration: 200; easing.type: Easing.InOutQuart }
        }
    }

    Row {
        id: wsRow
        spacing: 4

        Repeater {
            id: wsRepeater
            model: root.sortedWorkspaces

            delegate: Item {
                id: wsItem
                required property var modelData

                readonly property bool isActive: modelData.monitor === root.hyprMonitor && modelData.active
                readonly property bool isUrgent: modelData.urgent

                width: wsText.implicitWidth + 20
                height: wsText.implicitHeight + 8

                function claimIndicator() {
                    if (!wsItem.isActive) return
                    indicator.x = wsItem.x
                    indicator.width = wsItem.width
                }

                onIsActiveChanged: claimIndicator()
                onXChanged: claimIndicator()
                onWidthChanged: claimIndicator()
                Component.onCompleted: claimIndicator()

                Text {
                    id: wsText
                    anchors.centerIn: parent
                    text: wsItem.modelData.name
                    color: wsItem.isActive ? Theme.background
                         : wsItem.isUrgent ? Theme.color1
                         : Theme.foreground
                    font.pixelSize: 14
                    font.bold: wsItem.isActive
                }

                TapHandler {
                    onTapped: wsItem.modelData.activate()
                }
            }
        }
    }
}
