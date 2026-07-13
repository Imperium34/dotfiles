import qs
import Quickshell.Networking
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: root
    required property var network

    readonly property bool isConnected: network ? (network.connected ?? false) : false
    readonly property bool isChanging: network ? (network.stateChanging ?? false) : false
    readonly property bool needsPassword: {
        if (!network) return false
        if (isConnected || network.known) return false
        const s = network.security
        return s !== WifiSecurityType.None && s !== WifiSecurityType.Unknown
    }

    property bool expanded: false
    property string errorText: ""

    onIsChangingChanged: if (!isChanging && !isConnected) expanded = true
    onIsConnectedChanged: if (isConnected) expanded = false

    Connections {
        target: root.network
        function onConnectionFailed(reason) {
            root.errorText = reason === ConnectionFailReason.NoSecrets
                || reason === ConnectionFailReason.SecretsRequired
                ? "Wrong password"
                : "Connection failed"
            root.expanded = true
            Qt.callLater(() => passwordField.forceActiveFocus())
        }
    }

    height: expanded ? expandedHeight : baseHeight
    readonly property int baseHeight: 52
    readonly property int expandedHeight: 52 + 44 + (errorText !== "" ? 24 : 0) + 8

    Behavior on height {
        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
    }

    clip: true

    HoverHandler { id: rowHover }

    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        radius: 8
        color: rowHover.hovered
            ? Theme.hexToRgba(Theme.foreground, 0.07)
            : "transparent"
        Behavior on color {
            ColorAnimation { duration: 100 }
        }
    }

    RowLayout {
        id: baseRow
        x: 16
        y: 0
        width: parent.width - 32
        height: root.baseHeight
        spacing: 10

        Text {
            text: {
                const s = network ? network.signalStrength : 0
                if (s < 0.25) return "󰤟"
                if (s < 0.5)  return "󰤢"
                if (s < 0.75) return "󰤥"
                return "󰤨"
            }
            color: isConnected ? Theme.color5 : Theme.hexToRgba(Theme.foreground, 0.7)
            font.pixelSize: 16
            font.family: "Symbols Nerd Font"
        }

        Text {
            Layout.fillWidth: true
            text: network ? network.name : ""
            color: isConnected ? Theme.foreground : Theme.hexToRgba(Theme.foreground, 0.85)
            font.pixelSize: 13
            font.bold: isConnected
            elide: Text.ElideRight
        }

        Text {
            text: "󰌾"
            color: Theme.hexToRgba(Theme.foreground, 0.4)
            font.pixelSize: 12
            font.family: "Symbols Nerd Font"
            visible: network
                && network.security !== WifiSecurityType.None
                && network.security !== WifiSecurityType.Unknown
        }

        Loader {
            active: isConnected || isChanging
            sourceComponent: isChanging ? spinnerComponent : checkComponent
        }
    }

    Column {
        x: 16
        y: root.baseHeight
        width: parent.width - 32
        spacing: 6
        opacity: root.expanded ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }

        RowLayout {
            width: parent.width
            spacing: 6

            Rectangle {
                Layout.fillWidth: true
                height: 32
                radius: 8
                color: Theme.hexToRgba(Theme.foreground, 0.08)
                border.color: passwordField.activeFocus
                    ? Theme.hexToRgba(Theme.color5, 0.6)
                    : "transparent"
                border.width: 1

                Behavior on border.color {
                    ColorAnimation { duration: 100 }
                }

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: 10
                        rightMargin: 6
                    }
                    spacing: 4

                    TextInput {
                        id: passwordField
                        Layout.fillWidth: true
                        echoMode: showPassword ? TextInput.Normal : TextInput.Password
                        color: Theme.foreground
                        font.pixelSize: 13
                        selectionColor: Theme.hexToRgba(Theme.color5, 0.4)
                        verticalAlignment: TextInput.AlignVCenter
                        clip: true

                        property bool showPassword: false

                        onVisibleChanged: if (!visible) text = ""

                        Keys.onReturnPressed: connectButton.trigger()
                        Keys.onEscapePressed: {
                            root.expanded = false
                            root.errorText = ""
                        }
                    }

                    Text {
                        text: passwordField.showPassword ? "󰛑" : "󰛐"
                        color: Theme.hexToRgba(Theme.foreground, 0.5)
                        font.pixelSize: 14
                        font.family: "Symbols Nerd Font"

                        TapHandler {
                            onTapped: passwordField.showPassword = !passwordField.showPassword
                        }
                    }
                }
            }

            Rectangle {
                id: connectButton
                width: 64
                height: 32
                radius: 8
                color: connectHover.hovered
                    ? Theme.color5
                    : Theme.hexToRgba(Theme.color5, 0.7)

                Behavior on color {
                    ColorAnimation { duration: 100 }
                }

                HoverHandler { id: connectHover }

                Text {
                    anchors.centerIn: parent
                    text: "Join"
                    color: Theme.background
                    font.pixelSize: 12
                    font.bold: true
                }

                function trigger() {
                    if (passwordField.text.length < 8) {
                        root.errorText = "Password too short"
                        return
                    }
                    root.errorText = ""
                    network.connectWithPsk(passwordField.text)
                }

                TapHandler {
                    onTapped: connectButton.trigger()
                }
            }
        }

        Text {
            width: parent.width
            text: root.errorText
            color: Theme.color1
            font.pixelSize: 11
            visible: root.errorText !== ""
            leftPadding: 4
        }
    }

    TapHandler {
        onTapped: (eventPoint) => {
            if (eventPoint.position.y >= root.baseHeight) return
            if (isConnected) {
                network.disconnect()
            } else if (isChanging) {
                // do nothing
            } else if (root.needsPassword) {
                root.errorText = ""
                root.expanded = !root.expanded
                if (root.expanded) Qt.callLater(() => passwordField.forceActiveFocus())
            } else {
                network.connect()
            }
        }
    }

    Component {
        id: checkComponent
        Text {
            text: "󰄬"
            color: Theme.color5
            font.pixelSize: 14
            font.family: "Symbols Nerd Font"
        }
    }

    Component {
        id: spinnerComponent
        Text {
            text: "󰑙"
            color: Theme.hexToRgba(Theme.foreground, 0.6)
            font.pixelSize: 14
            font.family: "Symbols Nerd Font"
            RotationAnimator on rotation {
                from: 0; to: 360
                duration: 1000
                loops: Animation.Infinite
                running: true
            }
        }
    }
}
