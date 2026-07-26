import QtQuick

Item {
    id: root

    property int animEnter: 260
    property int animExit: 220
    property bool animIn: false

    signal closed()

    function open() {
        closeTimer.stop()
        animIn = true
    }

    function close() {
        animIn = false
        closeTimer.start()
    }

    Timer {
        id: closeTimer
        interval: root.animExit
        onTriggered: root.closed()
    }
}
