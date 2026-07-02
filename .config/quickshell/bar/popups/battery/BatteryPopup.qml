import "../../widgets"
import qs
import qs.widgets
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts

BasePopup {
    id: popup

    implicitWidth: 300
    implicitHeight: contentCol.implicitHeight + 32

    readonly property var bat: UPower.displayDevice
    readonly property bool charging: bat.state === UPowerDeviceState.Charging
                                  || bat.state === UPowerDeviceState.PendingCharge
    readonly property string nativePath: bat.ready ? bat.nativePath : "BAT0"

    readonly property color levelColor: {
        if (!bat.ready) return Theme.foreground
        if (bat.percentage * 100 <= 15) return Theme.color1
        if (bat.percentage * 100 <= 30) return Theme.color3
        return charging ? Theme.color2 : Theme.color5
    }

    property string tlpProfile: ""
    property string thresholdStart: ""
    property string thresholdEnd: ""
    readonly property bool thresholdSupported: thresholdStart !== "" && thresholdEnd !== ""

    function formatDuration(seconds) {
        if (!seconds || seconds <= 0) return "—"
        const h = Math.floor(seconds / 3600)
        const m = Math.round((seconds % 3600) / 60)
        return h > 0 ? (h + "h " + m + "m") : (m + "m")
    }

    readonly property string timeText: {
        if (!bat.ready || charging === undefined) return "—"
        if (charging) return formatDuration(bat.timeToFull) + " to full"
        return formatDuration(bat.timeToEmpty) + " remaining"
    }

    readonly property string powerText: {
        if (!bat.ready || bat.changeRate === 0) return "—"
        return Math.abs(bat.changeRate).toFixed(1) + " W " + (charging ? "charging" : "discharging")
    }

    function profileLabel(id) {
        if (id === "performance") return "Performance"
        if (id === "balanced") return "Balanced"
        if (id === "power-saver") return "Power Saver"
        return id || "—"
    }

    function refreshProfile() { profileProc.running = true }
    function refreshThresholds() { thresholdProc.running = true }

    function setProfile(name) {
        popup.tlpProfile = name
        Quickshell.execDetached(["/usr/bin/tlpctl", "set", name])
        confirmTimer.restart()
    }

    onAnimInChanged: {
        if (animIn) {
            refreshProfile()
            refreshThresholds()
        }
    }

    Timer {
        id: confirmTimer
        interval: 400
        onTriggered: popup.refreshProfile()
    }

    Timer {
        interval: 3000
        repeat: true
        running: popup.animIn
        onTriggered: {
            popup.refreshProfile()
            popup.refreshThresholds()
        }
    }

    Process {
        id: profileProc
        command: ["/usr/bin/tlpctl", "get"]
        stdout: StdioCollector {
            onStreamFinished: popup.tlpProfile = text.trim()
        }
    }

    Process {
        id: thresholdProc
        command: ["/usr/bin/bash", "-c",
            `S=$(cat /sys/class/power_supply/${popup.nativePath}/charge_control_start_threshold 2>/dev/null || cat /sys/class/power_supply/${popup.nativePath}/charge_start_threshold 2>/dev/null); ` +
            `E=$(cat /sys/class/power_supply/${popup.nativePath}/charge_control_end_threshold 2>/dev/null || cat /sys/class/power_supply/${popup.nativePath}/charge_stop_threshold 2>/dev/null); ` +
            `echo "$S|$E"`
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split("|")
                popup.thresholdStart = parts[0] || ""
                popup.thresholdEnd = parts.length > 1 ? parts[1] : ""
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 16
        color: Theme.hexToRgba(Theme.background, 0.92)
        border.color: Theme.hexToRgba(Theme.foreground, 0.1)
        border.width: 1

        opacity: popup.animIn ? 1 : 0
        scale: popup.animIn ? 1 : 0.95
        transformOrigin: Item.Top
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        ColumnLayout {
            id: contentCol
            anchors {
                fill: parent
                margins: 16
            }
            spacing: 14

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Battery"
                    color: Theme.foreground
                    font.pixelSize: 13
                    font.bold: true
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: popup.bat.ready ? Math.round(popup.bat.percentage * 100) + "%" : "--"
                    color: popup.levelColor
                    font.pixelSize: 12
                    font.bold: true
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 8
                radius: 4
                color: Theme.hexToRgba(Theme.foreground, 0.1)

                Rectangle {
                    anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                    width: parent.width * (popup.bat.ready ? popup.bat.percentage : 0)
                    radius: 4
                    color: popup.levelColor
                    Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Text { text: "Time remaining"; color: Theme.hexToRgba(Theme.foreground, 0.8); font.pixelSize: 12 }
                Item { Layout.fillWidth: true }
                Text { text: popup.timeText; color: Theme.hexToRgba(Theme.foreground, 0.6); font.pixelSize: 12 }
            }

            RowLayout {
                Layout.fillWidth: true
                Text { text: "Power draw"; color: Theme.hexToRgba(Theme.foreground, 0.8); font.pixelSize: 12 }
                Item { Layout.fillWidth: true }
                Text { text: popup.powerText; color: Theme.hexToRgba(Theme.foreground, 0.6); font.pixelSize: 12 }
            }

            RowLayout {
                Layout.fillWidth: true
                Text { text: "Health"; color: Theme.hexToRgba(Theme.foreground, 0.8); font.pixelSize: 12 }
                Item { Layout.fillWidth: true }
                Text {
                    text: popup.bat.healthSupported ? Math.round(popup.bat.healthPercentage) + "%" : "—"
                    color: Theme.hexToRgba(Theme.foreground, 0.6)
                    font.pixelSize: 12
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.hexToRgba(Theme.foreground, 0.08) }

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Charge limit"
                    color: Theme.foreground
                    font.pixelSize: 13
                    font.bold: true
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: popup.thresholdSupported
                        ? (popup.thresholdStart + "% – " + popup.thresholdEnd + "%")
                        : "Not available"
                    color: Theme.hexToRgba(Theme.foreground, 0.6)
                    font.pixelSize: 12
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.hexToRgba(Theme.foreground, 0.08) }

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "TLP Profile"
                    color: Theme.foreground
                    font.pixelSize: 13
                    font.bold: true
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: popup.profileLabel(popup.tlpProfile)
                    color: Theme.hexToRgba(Theme.foreground, 0.6)
                    font.pixelSize: 12
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: [
                        { id: "performance", label: "Perf" },
                        { id: "balanced", label: "Balanced" },
                        { id: "power-saver", label: "Saver" }
                    ]

                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool active: popup.tlpProfile === modelData.id

                        Layout.fillWidth: true
                        height: 28
                        radius: 8
                        color: active
                            ? Theme.hexToRgba(Theme.color4, 0.7)
                            : (btnHover.hovered ? Theme.hexToRgba(Theme.foreground, 0.07) : Theme.hexToRgba(Theme.foreground, 0.04))

                        Behavior on color { ColorAnimation { duration: 100 } }

                        HoverHandler { id: btnHover }

                        Text {
                            anchors.centerIn: parent
                            text: modelData.label
                            font.pixelSize: 11
                            font.bold: parent.active
                            color: parent.active ? Theme.background : Theme.foreground
                        }

                        TapHandler {
                            onTapped: popup.setProfile(modelData.id)
                        }
                    }
                }
            }
        }
    }
}
