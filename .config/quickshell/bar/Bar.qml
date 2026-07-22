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

            WlrLayershell.namespace: "quickshell:bar"

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
                Pill {
                    id: leftPill
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                    }
                    padding: 8
                    spacing: 8

                    PowerButton { barWindow: barWindow }
                    Workspaces { screen: barWindow.screen }
                    MediaPlayer {
                        id: mediaWidget
                        barWindow: barWindow
                    }
                }

                // ── CENTER PILL ───────────────────────────────
                Pill {
                    id: centerPill
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        verticalCenter: parent.verticalCenter
                    }
                    padding: 10
                    spacing: 10

                    transformOrigin: Item.Center
                    scale: wallpaperPicker.animIn ? 0.15 : 1
                    opacity: wallpaperPicker.animIn ? 0 : 1

                    Behavior on scale {
                        NumberAnimation {
                            duration: wallpaperPicker.animIn ? 220 : 260
                            easing.type: Easing.OutCubic
                        }
                    }
                    Behavior on opacity {
                        NumberAnimation {
                            duration: wallpaperPicker.animIn ? 150 : 200
                            easing.type: Easing.OutCubic
                        }
                    }

                    SysMonitor { barWindow: barWindow; side: "cpu" }
                    Clock { barWindow: barWindow }
                    SysMonitor { barWindow: barWindow; side: "ram" }
                }

                // ── RIGHT PILL ────────────────────────────────
                Pill {
                    id: rightPill
                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    padding: 15
                    spacing: 8

                    IdleInhibitor {}
                    Audio { barWindow: barWindow }
                    Backlight {}
                    Network { barWindow: barWindow }
                    Bluetooth { barWindow: barWindow }
                    Battery { barWindow: barWindow }
                    Tray { barWindow: barWindow }
                    NotificationBell { barWindow: barWindow }
                }

                Wallpaper {
                    id: wallpaperPicker
                    barWindow: barWindow
                    originX: barWindow.width / 2
                    originWidth: centerPill.width
                }
            }
        }
    }
}
