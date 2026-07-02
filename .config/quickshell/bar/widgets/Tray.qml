import qs
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    // display() needs a window to anchor the tray menu to. This was undefined,
    // so right-click and menu-only items silently failed. Passed in from Bar.qml
    // the same way every other popup-owning widget receives it.
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
                required property var modelData

                implicitWidth: 18
                implicitHeight: 18

                IconImage {
                    anchors.centerIn: parent
                    source: modelData.icon
                    implicitSize: 18
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.RightButton || modelData.onlyMenu) {
                            // use the parameter's coords — bare mouseX/mouseY can
                            // resolve to 0,0 inside an arrow handler, which gave
                            // display() a degenerate anchor and the menu never showed.
                            modelData.display(root.barWindow, mouse.x, mouse.y)
                        } else {
                            modelData.activate()
                        }
                    }
                }
            }
        }
    }
}
