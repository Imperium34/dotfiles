import QtQuick

Item {
    id: root

    required property var barWindow
    property var popup: null
    signal rightClicked()

    readonly property bool pressed: leftTap.pressed

    default property alias content: contentSlot.data

    Item {
        id: contentSlot
        anchors.fill: parent
    }

    Binding {
        target: root.popup
        property: "barWindow"
        value: root.barWindow
        when: root.popup !== null
    }

    function openPopup() {
        if (!root.popup) return
        const centerX = root.mapToItem(null, root.width / 2, 0).x
        root.popup.anchorX = Math.round(centerX - root.popup.implicitWidth / 2)
        root.popup.triggerX = Math.round(centerX - root.width / 2)
        root.popup.triggerWidth = root.width
        root.popup.toggle()
    }

    TapHandler {
        id: leftTap
        acceptedButtons: Qt.LeftButton
        onTapped: root.openPopup()
    }

    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: root.rightClicked()
    }
}
