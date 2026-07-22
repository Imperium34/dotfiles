import qs
import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

Item {
    required property var screen
    readonly property var hyprMonitor: Hyprland.monitorFor(screen)

    readonly property var sortedWorkspaces: {
        const ws = Hyprland.workspaces.values.filter(w => !w.name.startsWith("special:"))
        ws.sort((a, b) => a.id - b.id)
        return ws
    }

    readonly property var activeWorkspace: {
        for (const ws of sortedWorkspaces) {
            if (ws.monitor === hyprMonitor && ws.active) return ws
        }
        return null
    }

    implicitWidth: wsRow.implicitWidth
    implicitHeight: wsRow.implicitHeight

    function updateIndicator() {
        if (!activeWorkspace) return
        let targetIdx = -1
        for (let i = 0; i < sortedWorkspaces.length; i++) {
            if (sortedWorkspaces[i].id === activeWorkspace.id) {
                targetIdx = i
                break
            }
        }
        if (targetIdx < 0) return

        let xPos = 0
        for (let i = 0; i < targetIdx; i++) {
            const delegate = wsRepeater.itemAt(i)
            if (!delegate) return
            xPos += delegate.width + wsRow.spacing
        }
        const activeDelegate = wsRepeater.itemAt(targetIdx)
        if (!activeDelegate) return
        indicator.x = xPos
        indicator.width = activeDelegate.width
      }

    onActiveWorkspaceChanged: {
        Qt.callLater(updateIndicator)
    }

    onSortedWorkspacesChanged: Qt.callLater(updateIndicator)

    Rectangle {
        id: indicator
        y: 0
        height: parent.height
        radius: height / 2
        color: Theme.color4
        visible: activeWorkspace !== null

        Behavior on x {
            NumberAnimation {
                duration: 200
                easing.type: Easing.InOutQuart
            }
        }
        Behavior on width {
            NumberAnimation {
                duration: 200
                easing.type: Easing.InOutQuart
            }
        }
    }

    Row {
        id: wsRow
        spacing: 4

        Repeater {
            id: wsRepeater
            model: sortedWorkspaces

            onItemAdded: (index, item) => {
                if (count === sortedWorkspaces.length) updateIndicator()
            }

            delegate: Item {
                required property var modelData
                readonly property bool isActive: modelData.monitor === hyprMonitor && modelData.active
                readonly property bool isUrgent: modelData.urgent

                width: wsText.implicitWidth + 20
                height: wsText.implicitHeight + 8

                Text {
                    id: wsText
                    anchors.centerIn: parent
                    text: modelData.name
                    color: isActive ? Theme.background
                         : isUrgent ? Theme.color1
                         : Theme.foreground
                    font.pixelSize: 14
                    font.bold: isActive
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: modelData.activate()
                }
            }
        }
    }
}
