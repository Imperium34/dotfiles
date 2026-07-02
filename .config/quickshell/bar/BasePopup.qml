import qs
import Quickshell
import Quickshell.Hyprland
import QtQuick

PopupWindow {
    id: root

    required property var barWindow

    property int anchorX: 0

    color: "transparent"
    visible: false

    anchor.window: barWindow
    anchor.rect.x: anchorX
    anchor.rect.y: barWindow.height + 8

    property bool animIn: false

    function open() {
        closeTimer.stop()
        visible = true
        focusGrab.active = true
        animIn = true
    }

    function close() {
        animIn = false
        focusGrab.active = false
        closeTimer.start()
    }

    function toggle() {
        if (visible && animIn) close()
        else open()
    }

    Timer {
        id: closeTimer
        interval: 200
        onTriggered: root.visible = false
    }

    HyprlandFocusGrab {
        id: focusGrab
        windows: [root]
        onCleared: root.close()
    }

    default property alias content: contentSlot.data

    Item {
        id: contentSlot
        anchors.fill: parent
    }
}
