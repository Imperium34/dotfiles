import qs
import qs.components
import qs.widgets
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts

BasePopup {
    id: popup

    implicitWidth: 320
    implicitHeight: Math.min(contentCol.implicitHeight + 32, 400)

    // "output" | "input" | "apps"
    property string mode: "output"
    readonly property bool appsMode: mode === "apps"

    readonly property var sinkNodes: Pipewire.nodes.values.filter(n =>
        n.audio && n.isSink && !n.isStream)
    readonly property var sourceNodes: Pipewire.nodes.values.filter(n =>
        n.audio && !n.isSink && !n.isStream)

    readonly property var streamNodes: Pipewire.nodes.values.filter(n =>
        n.audio && n.isStream)

    readonly property var activeNodes: {
        if (popup.appsMode) return popup.streamNodes
        return popup.mode === "input" ? popup.sourceNodes : popup.sinkNodes
    }

    PwObjectTracker {
        objects: popup.activeNodes
    }

    function selectNode(node) {
        if (popup.mode === "input") {
            Pipewire.preferredDefaultAudioSource = node
        } else if (popup.mode === "output") {
            Pipewire.preferredDefaultAudioSink = node
        }
    }

    function streamLabel(node) {
        if (!node) return ""
        const p = node.properties || {}
        return p["application.name"]
            || p["media.name"]
            || node.description
            || node.name
            || "Unknown"
    }

    function streamIcon(node) {
        if (!node) return ""
        const p = node.properties || {}
        const name = p["application.icon-name"] || p["application.name"] || ""
        return name === "" ? "" : Quickshell.iconPath(name, true)
    }

    ColumnLayout {
        id: contentCol
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: 16
        }
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: [
                    { label: "Output", value: "output" },
                    { label: "Input", value: "input" },
                    { label: "Apps", value: "apps" }
                ]
                delegate: Rectangle {
                    id: tab
                    required property var modelData
                    readonly property bool active: popup.mode === modelData.value

                    implicitWidth: tabText.implicitWidth + 20
                    implicitHeight: 26
                    radius: 13
                    color: tab.active
                        ? Theme.hexToRgba(Theme.color4, 0.7)
                        : (tabHover.hovered ? Theme.hexToRgba(Theme.foreground, 0.08) : "transparent")

                    Behavior on color { ColorAnimation { duration: 100 } }

                    HoverHandler { id: tabHover }

                    Text {
                        id: tabText
                        anchors.centerIn: parent
                        text: tab.modelData.label
                        font.pixelSize: 12
                        font.bold: tab.active
                        color: tab.active ? Theme.background : Theme.foreground
                    }

                    TapHandler {
                        onTapped: popup.mode = tab.modelData.value
                    }
                }
            }

            Item { Layout.fillWidth: true }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Theme.hexToRgba(Theme.foreground, 0.08)
        }

        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, 5 * (popup.appsMode ? 58 : 48))
            interactive: contentHeight > height
            clip: true
            spacing: 2
            model: popup.activeNodes

            Text {
                anchors.centerIn: parent
                visible: listView.count === 0
                text: popup.appsMode ? "Nothing playing" : "No devices found"
                color: Theme.hexToRgba(Theme.foreground, 0.5)
                font.pixelSize: 12
            }

            delegate: Item {
                id: row
                required property var modelData

                readonly property var nodeAudio: modelData ? modelData.audio : null
                readonly property bool isDefault: popup.mode === "input"
                    ? modelData === Pipewire.defaultAudioSource
                    : modelData === Pipewire.defaultAudioSink

                width: listView.width
                height: popup.appsMode ? 58 : 48

                Rectangle {
                    anchors.fill: parent
                    radius: 10
                    color: {
                        if (!popup.appsMode && row.isDefault)
                            return Theme.hexToRgba(Theme.color4, 0.12)
                        return rowHover.hovered
                            ? Theme.hexToRgba(Theme.foreground, 0.06)
                            : "transparent"
                    }
                    Behavior on color { ColorAnimation { duration: 100 } }
                }

                HoverHandler { id: rowHover }

                // ---- device row (output / input) ----
                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: 12
                        rightMargin: 12
                    }
                    spacing: 8
                    visible: !popup.appsMode

                    Text {
                        text: row.isDefault ? "󰄲" : "󰄱"
                        font.pixelSize: 15
                        font.family: "Symbols Nerd Font"
                        color: row.isDefault ? Theme.color4 : Theme.hexToRgba(Theme.foreground, 0.4)
                    }

                    Text {
                        Layout.fillWidth: true
                        text: row.modelData
                            ? (row.modelData.description || row.modelData.nickname || row.modelData.name)
                            : ""
                        elide: Text.ElideRight
                        font.pixelSize: 12
                        color: Theme.foreground
                    }
                }

                // ---- stream row (apps) ----
                ColumnLayout {
                    anchors {
                        fill: parent
                        leftMargin: 12
                        rightMargin: 12
                        topMargin: 6
                        bottomMargin: 6
                    }
                    spacing: 2
                    visible: popup.appsMode

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Image {
                            Layout.preferredWidth: 14
                            Layout.preferredHeight: 14
                            source: popup.appsMode ? popup.streamIcon(row.modelData) : ""
                            visible: source !== ""
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                        }

                        Text {
                            Layout.fillWidth: true
                            text: popup.appsMode ? popup.streamLabel(row.modelData) : ""
                            elide: Text.ElideRight
                            font.pixelSize: 12
                            color: Theme.foreground
                        }

                        Text {
                            text: row.nodeAudio
                                ? Math.round(row.nodeAudio.volume * 100) + "%"
                                : "--"
                            font.pixelSize: 10
                            font.family: "Departure Mono"
                            color: Theme.hexToRgba(Theme.foreground, 0.5)
                        }

                        Text {
                            text: (row.nodeAudio && row.nodeAudio.muted) ? "󰝟" : "󰕾"
                            font.pixelSize: 13
                            font.family: "Symbols Nerd Font"
                            color: (row.nodeAudio && row.nodeAudio.muted)
                                ? Theme.color1
                                : Theme.hexToRgba(Theme.foreground, 0.6)

                            TapHandler {
                                onTapped: if (row.nodeAudio)
                                    row.nodeAudio.muted = !row.nodeAudio.muted
                            }
                        }
                    }

                    Item {
                        id: strSlider
                        Layout.fillWidth: true
                        Layout.preferredHeight: 16

                        Rectangle {
                            anchors {
                                left: parent.left
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                            }
                            height: 5
                            radius: 2.5
                            color: Theme.hexToRgba(Theme.foreground, 0.15)

                            Rectangle {
                                width: parent.width * (row.nodeAudio
                                    ? (row.nodeAudio.muted ? 0 : row.nodeAudio.volume)
                                    : 0)
                                height: parent.height
                                radius: 2.5
                                color: Theme.color5
                                Behavior on width { NumberAnimation { duration: 80 } }
                            }
                        }

                        function setFromX(x) {
                            if (!row.nodeAudio) return
                            row.nodeAudio.volume = Math.max(0, Math.min(1, x / strSlider.width))
                        }

                        TapHandler {
                            onTapped: (ep) => strSlider.setFromX(ep.position.x)
                        }
                        DragHandler {
                            target: null
                            yAxis.enabled: false
                            onCentroidChanged: if (active) strSlider.setFromX(centroid.position.x)
                        }
                    }
                }

                TapHandler {
                    enabled: !popup.appsMode
                    onTapped: popup.selectNode(row.modelData)
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Theme.hexToRgba(Theme.foreground, 0.08)
        }

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
