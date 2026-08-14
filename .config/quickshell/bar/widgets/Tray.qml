import qs
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property var barWindow

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 4

        Repeater {
            model: SystemTray.items

            delegate: Item {
                id: trayItem
                required property var modelData

                implicitWidth: 18
                implicitHeight: 18

                IconImage {
                    anchors.centerIn: parent
                    source: trayItem.modelData.icon
                    implicitSize: 18
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.RightButton || trayItem.modelData.onlyMenu) {
                            const p = mapToItem(null, mouse.x, mouse.y)
                            trayItem.modelData.display(root.barWindow, p.x, p.y)
                        } else {
                            trayItem.modelData.activate()
                        }
                    }
                }
            }
        }
    }
}
