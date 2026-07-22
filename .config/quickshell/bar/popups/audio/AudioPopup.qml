import qs
import "../../widgets"
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts

BasePopup {
    id: popup

    implicitWidth: 300
    implicitHeight: Math.min(contentCol.implicitHeight + 32, 380)

    property bool showInputs: false

    readonly property var sinkNodes: Pipewire.nodes.values.filter(n =>
        n.audio && n.isSink && !n.isStream)
    readonly property var sourceNodes: Pipewire.nodes.values.filter(n =>
        n.audio && !n.isSink && !n.isStream)
    readonly property var activeNodes: showInputs ? sourceNodes : sinkNodes

    PwObjectTracker {
        objects: popup.activeNodes
    }

    function selectNode(node) {
        if (popup.showInputs) {
            Pipewire.preferredDefaultAudioSource = node
        } else {
            Pipewire.preferredDefaultAudioSink = node
        }
    }

    ColumnLayout {
        id: contentCol
        anchors {
            fill: parent
            margins: 16
        }
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: [
                    { label: "Output", value: false },
                    { label: "Input", value: true }
                ]
                delegate: Rectangle {
                    required property var modelData
                    readonly property bool active: popup.showInputs === modelData.value

                    implicitWidth: tabText.implicitWidth + 20
                    implicitHeight: 26
                    radius: 13
                    color: active
                        ? Theme.hexToRgba(Theme.color4, 0.7)
                        : (tabHover.hovered ? Theme.hexToRgba(Theme.foreground, 0.08) : "transparent")

                    Behavior on color { ColorAnimation { duration: 100 } }

                    HoverHandler { id: tabHover }

                    Text {
                        id: tabText
                        anchors.centerIn: parent
                        text: modelData.label
                        font.pixelSize: 12
                        font.bold: parent.active
                        color: parent.active ? Theme.background : Theme.foreground
                    }

                    TapHandler {
                        onTapped: popup.showInputs = modelData.value
                    }
                }
            }

            Item { Layout.fillWidth: true }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.hexToRgba(Theme.foreground, 0.08) }

        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, 5 * 52)
            interactive: contentHeight > height
            clip: true
            spacing: 2
            model: popup.activeNodes

            Text {
                anchors.centerIn: parent
                visible: listView.count === 0
                text: "No devices found"
                color: Theme.hexToRgba(Theme.foreground, 0.5)
                font.pixelSize: 12
            }

            delegate: Item {
                required property var modelData
                width: listView.width
                height: 48

                readonly property bool isDefault: popup.showInputs
                    ? modelData === Pipewire.defaultAudioSource
                    : modelData === Pipewire.defaultAudioSink

                Rectangle {
                    anchors.fill: parent
                    radius: 10
                    color: isDefault
                        ? Theme.hexToRgba(Theme.color4, 0.12)
                        : (rowHover.hovered ? Theme.hexToRgba(Theme.foreground, 0.06) : "transparent")
                    Behavior on color { ColorAnimation { duration: 100 } }
                }

                HoverHandler { id: rowHover }

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: 12
                        rightMargin: 12
                    }
                    spacing: 8

                    Text {
                        text: isDefault ? "󰄲" : "󰄱"
                        font.pixelSize: 15
                        font.family: "Symbols Nerd Font"
                        color: isDefault ? Theme.color4 : Theme.hexToRgba(Theme.foreground, 0.4)
                    }

                    Text {
                        Layout.fillWidth: true
                        text: modelData.description || modelData.nickname || modelData.name
                        elide: Text.ElideRight
                        font.pixelSize: 12
                        color: Theme.foreground
                    }
                }

                TapHandler {
                    onTapped: popup.selectNode(modelData)
                }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.hexToRgba(Theme.foreground, 0.08) }

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "Sound Settings"
                color: Theme.hexToRgba(Theme.foreground, 0.7)
                font.pixelSize: 12
            }
            Item { Layout.fillWidth: true }

            TapHandler {
                onTapped: Quickshell.execDetached(["pavucontrol"])
            }
        }
    }
}
