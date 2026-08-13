import qs
import qs.services
import qs.widgets
import Quickshell
import QtQuick
import QtQuick.Layouts

BasePopup {
    id: popup

    implicitWidth: 380
    implicitHeight: contentCol.implicitHeight + 32

    onAnimInChanged: {
        if (animIn) SysInfo.startGpuPolling()
        else SysInfo.stopGpuPolling()
    }

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
                text: "CPU"
                color: Theme.foreground
                font.pixelSize: 13
                font.bold: true
            }
            Item { Layout.fillWidth: true }
            Text {
                text: Math.round(SysInfo.cpuUsage * 100) + "%"
                color: Theme.hexToRgba(Theme.foreground, 0.6)
                font.pixelSize: 12
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 8
            rowSpacing: 6
            columnSpacing: 6

            Repeater {
                model: SysInfo.perCore
                delegate: Rectangle {
                    Layout.fillWidth: true
                    height: 22
                    radius: 4
                    color: Theme.hexToRgba(Theme.foreground, 0.08)
                    clip: true

                    readonly property real coreUsage: modelData.usage

                    Rectangle {
                        anchors {
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                        }
                        height: parent.height * parent.coreUsage
                        radius: 4
                        color: parent.coreUsage >= 0.9
                            ? "#e0405a"
                            : Theme.hexToRgba(Theme.color5, 0.85)
                        Behavior on height {
                            NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
                        }
                    }
                }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.hexToRgba(Theme.foreground, 0.08) }

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "Memory"
                color: Theme.foreground
                font.pixelSize: 13
                font.bold: true
            }
            Item { Layout.fillWidth: true }
            Text {
                text: (SysInfo.memUsedKb / 1048576).toFixed(1) + " / "
                    + (SysInfo.memTotalKb / 1048576).toFixed(1) + " GiB"
                color: Theme.hexToRgba(Theme.foreground, 0.6)
                font.pixelSize: 12
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 8
            radius: 4
            color: Theme.hexToRgba(Theme.foreground, 0.1)

            Rectangle {
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                width: parent.width * SysInfo.memUsage
                radius: 4
                color: SysInfo.memUsage >= 0.9 ? "#e0405a" : Theme.color5
                Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.hexToRgba(Theme.foreground, 0.08) }

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "GPU"
                color: Theme.foreground
                font.pixelSize: 13
                font.bold: true
            }
            Item { Layout.fillWidth: true }
            Text {
                text: Math.round(SysInfo.gpuUtil * 100) + "%  ·  "
                    + Math.round(SysInfo.gpuTempC) + "°C  ·  "
                    + SysInfo.gpuPowerW.toFixed(0) + "W"
                color: Theme.hexToRgba(Theme.foreground, 0.6)
                font.pixelSize: 12
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "VRAM"
                color: Theme.hexToRgba(Theme.foreground, 0.8)
                font.pixelSize: 12
            }
            Item { Layout.fillWidth: true }
            Text {
                text: (SysInfo.gpuMemUsedMb / 1024).toFixed(1) + " / "
                    + (SysInfo.gpuMemTotalMb / 1024).toFixed(1) + " GiB"
                color: Theme.hexToRgba(Theme.foreground, 0.6)
                font.pixelSize: 12
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 8
            radius: 4
            color: Theme.hexToRgba(Theme.foreground, 0.1)

            readonly property real vramFrac: SysInfo.gpuMemTotalMb > 0
                ? SysInfo.gpuMemUsedMb / SysInfo.gpuMemTotalMb : 0

            Rectangle {
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                width: parent.width * parent.vramFrac
                radius: 4
                color: parent.vramFrac >= 0.9 ? "#e0405a" : Theme.color5
                Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
            }
        }
    }
}
