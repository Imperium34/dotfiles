import qs
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Effects

PanelWindow {
    id: root

    property var barWindow: null
    property int anchorX: 0
    property real anchorY: barWindow ? barWindow.height + 16 : 68

    property string layerNamespace: "quickshell:popup"
    property var keyboardFocus: WlrKeyboardFocus.OnDemand

    // ---- card options ----
    property int animEnter: 220
    property int animExit: 150
    property real startScale: 0.96
    property real cardOpacity: 0.7
    property bool cardClip: true
    property bool roundedMask: false

    color: "transparent"
    visible: false
    screen: barWindow ? barWindow.screen : null

    anchors.top: true
    anchors.left: true
    margins {
        top: root.anchorY
        left: Math.max(8, Math.min(root.anchorX,
            (root.screen ? root.screen.width : 1920) - root.implicitWidth - 8))
    }
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: root.layerNamespace
    WlrLayershell.keyboardFocus: root.keyboardFocus

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
        interval: root.animExit + 30
        onTriggered: root.visible = false
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
        anchors.fill: parent
        radius: 16
        antialiasing: true
        color: Theme.hexToRgba(Theme.background, root.cardOpacity)
        border.color: Theme.hexToRgba(Theme.foreground, 0.1)
        border.width: 1
        clip: root.cardClip && !root.roundedMask

        opacity: root.animIn ? 1 : (root.visible ? 0.45 : 0)
        scale: root.animIn ? 1 : root.startScale
        transformOrigin: Item.Top
        Behavior on opacity {
            NumberAnimation {
                duration: root.animIn ? root.animEnter : root.animExit
                easing.type: Easing.OutCubic
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: root.animIn ? root.animEnter : root.animExit
                easing.type: Easing.OutCubic
            }
        }

        layer.enabled: root.roundedMask
        layer.smooth: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: cornerMask
        }

        Item {
            id: contentSlot
            anchors.fill: parent
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
