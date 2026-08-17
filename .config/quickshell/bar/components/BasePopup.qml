import qs
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Effects

PopupWindow {
    id: root

    property var barWindow: null
    property int anchorX: 0
    property real anchorY: barWindow ? barWindow.height : 48

    // ---- card options ----
    property int animEnter: 220
    property int animExit: 150
    property int cardAnimDuration: root.animEnter
    property real cardOpacity: Theme.surfaceAlpha(0.7)
    property bool roundedMask: false
    property bool connectToBar: true
    property real triggerX: anchorX
    property real triggerWidth: 0

    color: "transparent"
    visible: false

    // ---- PopupWindow Positioning ----
    readonly property real resolvedAnchorX: Math.max(8, Math.min(root.anchorX, (barWindow?.screen?.width ?? 1920) - root.width - 8))

    readonly property real startCardWidth: (connectToBar && triggerWidth > 0) ? triggerWidth : width
    readonly property real startCardX: (connectToBar && triggerWidth > 0) ? (triggerX - resolvedAnchorX) : 0

    anchor.window: barWindow
    anchor.rect: Qt.rect(
        root.resolvedAnchorX,
        root.anchorY,
        0,
        0
    )

    readonly property bool animIn: controller.animIn

    function open() {
        visible = true
        focusGrab.active = true
        root.cardAnimDuration = root.animEnter
        controller.open()
    }

    function close() {
        focusGrab.active = false
        root.cardAnimDuration = root.animExit
        controller.close()
    }

    function toggle() {
        if (visible && controller.animIn) close()
        else open()
    }

    ExpandPopupController {
        id: controller
        animEnter: root.animEnter
        animExit: root.animExit + 30
        onClosed: root.visible = false
    }

    HyprlandFocusGrab {
        id: focusGrab
        windows: [root]
        onCleared: root.close()
    }

    default property alias content: contentSlot.data

    // ---- shared frosted, animated card ----
    Rectangle {
        id: card
        y: 0
        x: root.animIn ? 0 : root.startCardX
        width: root.animIn ? root.width : root.startCardWidth
        height: root.animIn ? root.height : 0
        radius: 16
        antialiasing: true
        color: Theme.hexToRgba(Theme.background, root.cardOpacity)
        border.color: Theme.hexToRgba(Theme.foreground, 0.1)
        border.width: 1
        clip: true

        opacity: root.animIn ? 1 : 0

        Behavior on x {
            NumberAnimation {
                duration: root.cardAnimDuration
                easing.type: Easing.OutCubic
            }
        }
        Behavior on width {
            NumberAnimation {
                duration: root.cardAnimDuration
                easing.type: Easing.OutCubic
            }
        }
        Behavior on height {
            NumberAnimation {
                duration: root.cardAnimDuration
                easing.type: Easing.OutCubic
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: root.cardAnimDuration
                easing.type: Easing.OutCubic
            }
        }

        layer.enabled: root.roundedMask
        layer.smooth: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: cornerMask
        }
    }

    // ---- content reveal layer ----
    Item {
        id: revealMask
        x: card.x
        y: card.y
        width: card.width
        height: card.height
        clip: true
        opacity: card.opacity

        Item {
            id: contentSlot
            x: 0
            y: 0
            width: root.width
            height: root.height
        }
    }

    Item {
        id: cornerMask
        anchors.fill: card
        layer.enabled: root.roundedMask
        visible: false
        Rectangle {
            anchors.fill: parent
            radius: card.radius
            color: "black"
        }
    }
}

