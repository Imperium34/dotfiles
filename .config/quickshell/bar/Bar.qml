import qs
import qs.widgets
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Services.Mpris
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: barWindow
            required property var modelData
            screen: modelData

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: 52
            margins.top: 8
            color: "transparent"

            exclusionMode: ExclusionMode.Normal
            exclusiveZone: 52

            Component.onCompleted: IdleInhibit.window = barWindow

            Item {
                id: pillRow
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    leftMargin: 10
                    rightMargin: 10
                }
                height: 44

                // ── LEFT PILL ─────────────────────────────────
                Rectangle {
                    id: leftPill
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                    }
                    height: 44
                    width: leftContent.implicitWidth + 16
                    radius: 22
                    color: Theme.hexToRgba(Theme.background, 0.85)
                    border.color: Theme.hexToRgba(Theme.foreground, 0.1)
                    border.width: 1

                    RowLayout {
                        id: leftContent
                        anchors.centerIn: parent
                        spacing: 8

                        PowerButton { barWindow: barWindow }
                        Workspaces { screen: barWindow.screen }
                        MediaPlayer {
                          id: mediaWidget
                          barWindow: barWindow
                        }
                    }
                }

                // ── CENTER PILL ───────────────────────────────
                Rectangle {
                    id: centerPill
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        verticalCenter: parent.verticalCenter
                    }
                    height: 44
                    width: centerContent.implicitWidth + 20
                    radius: 22
                    color: Theme.hexToRgba(Theme.background, 0.85)
                    border.color: Theme.hexToRgba(Theme.foreground, 0.1)
                    border.width: 1

                    RowLayout {
                        id: centerContent
                        anchors.centerIn: parent
                        spacing: 10

                        SysMonitor { barWindow: barWindow; side: "cpu" }
                        Clock { barWindow: barWindow }
                        SysMonitor { barWindow: barWindow; side: "ram" }
                    }
                }

                // ── RIGHT PILL ────────────────────────────────
                Rectangle {
                    id: rightPill
                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    height: 44
                    width: rightContent.implicitWidth + 30
                    radius: 22
                    color: Theme.hexToRgba(Theme.background, 0.85)
                    border.color: Theme.hexToRgba(Theme.foreground, 0.1)
                    border.width: 1

                    RowLayout {
                        id: rightContent
                        anchors.centerIn: parent
                        spacing: 8

                        IdleInhibitor {}
                        Audio {}
                        Backlight {}
                        Network { barWindow: barWindow }
                        Bluetooth { barWindow: barWindow }
                        Battery { barWindow: barWindow }
                        Tray { barWindow: barWindow }
                        NotificationBell { barWindow: barWindow }
                    }
                }
            }
        }
    }
}
