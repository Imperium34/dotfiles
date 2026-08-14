import qs
import qs.services
import qs.components
import qs.popups.network
import qs.popups.bluetooth
import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts

BaseExpandPopup {
    id: popup

    ipcTarget: "quicksettings"
    showSearch: false

    implicitWidth: 380
    implicitHeight: contentCol.implicitHeight + 24

    property string detail: ""

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var audio: sink ? sink.audio : null
    readonly property real volume: audio ? audio.volume : 0
    readonly property bool muted: audio ? audio.muted : false

    onOpened: {
        Brightness.refresh()
        NightLight.refresh()
    }

    onDetailChanged: {
        Net.scanning = (popup.detail === "wifi")
        if (BtService.adapter)
            BtService.adapter.discovering = (popup.detail === "bluetooth")
    }

    onVisibleChanged: if (!visible) popup.detail = ""

    readonly property string detailTitle: {
        if (popup.detail === "wifi") return "Wi-Fi"
        if (popup.detail === "bluetooth") return "Bluetooth"
        if (popup.detail === "nightlight") return "Night Light"
        return ""
    }

    ColumnLayout {
        id: contentCol
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        spacing: 10

        // ══ GRID ═══════════════════════════════════════════════
        ColumnLayout {
            id: mainPane
            Layout.fillWidth: true
            spacing: 10
            visible: popup.detail === ""

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 8
                rowSpacing: 8

                QuickSettingsTile {
                    Layout.fillWidth: true
                    icon: Net.icon
                    label: "Wi-Fi"
                    sublabel: Net.label
                    active: Net.wifiEnabled
                    interactive: Net.hasWifi && !Net.hardwareBlocked
                    hasDetail: Net.hasWifi
                    onActivated: Net.toggleWifi()
                    onDetailRequested: popup.detail = "wifi"
                }

                QuickSettingsTile {
                    Layout.fillWidth: true
                    icon: BtService.icon
                    label: "Bluetooth"
                    sublabel: BtService.connectedCount > 0
                        ? BtService.connectedCount + " connected"
                        : (BtService.enabled ? "On" : "Off")
                    active: BtService.enabled
                    interactive: BtService.adapter !== null
                    hasDetail: BtService.adapter !== null
                    onActivated: BtService.toggleEnabled()
                    onDetailRequested: popup.detail = "bluetooth"
                }

                QuickSettingsTile {
                    Layout.fillWidth: true
                    icon: Airplane.active ? "󰀝" : "󰀞"
                    label: "Airplane Mode"
                    sublabel: Airplane.active ? "Radios off" : "Radios on"
                    active: Airplane.active
                    interactive: Airplane.anyRadio
                    onActivated: Airplane.toggle()
                }

                QuickSettingsTile {
                    Layout.fillWidth: true
                    icon: NightLight.enabled ? "󰽥" : "󰃞"
                    label: "Night Light"
                    sublabel: NightLight.enabled ? NightLight.temperature + "K" : "Off"
                    active: NightLight.enabled
                    hasDetail: true
                    onActivated: NightLight.toggle()
                    onDetailRequested: popup.detail = "nightlight"
                }

                QuickSettingsTile {
                    Layout.fillWidth: true
                    icon: NotifService.dnd ? "󰂛" : "󰂚"
                    label: "Do Not Disturb"
                    sublabel: NotifService.count > 0 ? NotifService.count + " in centre" : ""
                    active: NotifService.dnd
                    onActivated: NotifService.toggleDnd()
                }

                QuickSettingsTile {
                    Layout.fillWidth: true
                    icon: IdleInhibit.inhibiting ? "󰅶" : "󰾪"
                    label: "Keep Awake"
                    sublabel: IdleInhibit.inhibiting ? "Idle blocked" : "Idle allowed"
                    active: IdleInhibit.inhibiting
                    interactive: IdleInhibit.window !== null
                    onActivated: IdleInhibit.inhibiting = !IdleInhibit.inhibiting
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Theme.hexToRgba(Theme.foreground, 0.08)
            }

            // ---- volume ----
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                SliderWidget {
                    Layout.fillWidth: true
                    alwaysExpanded: true
                    fontSize: 18

                    icon: {
                        if (!popup.audio || popup.muted) return "󰝟"
                        if (popup.volume === 0) return "󰝟"
                        if (popup.volume < 0.34) return "󰕿"
                        if (popup.volume < 0.67) return "󰖀"
                        return "󰕾"
                    }
                    iconColor: popup.muted ? Theme.color1 : Theme.foreground
                    fillColor: Theme.color5
                    value: popup.muted ? 0 : popup.volume

                    onSliderMoved: (v) => { if (popup.audio) popup.audio.volume = v }
                    onIconActivated: { if (popup.audio) popup.audio.muted = !popup.audio.muted }
                }

                Text {
                    text: popup.audio ? Math.round(popup.volume * 100) + "%" : "--"
                    color: Theme.hexToRgba(Theme.foreground, 0.6)
                    font.pixelSize: 11
                    font.family: "Departure Mono"
                    Layout.minimumWidth: 34
                    horizontalAlignment: Text.AlignRight
                }
            }

            // ---- brightness ----
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                visible: Brightness.available

                SliderWidget {
                    Layout.fillWidth: true
                    alwaysExpanded: true
                    fontSize: 18
                    icon: "󰖨"
                    iconColor: Theme.foreground
                    fillColor: Theme.color3
                    value: Brightness.fraction
                    onSliderMoved: (v) => Brightness.setPercent(v * 100)
                }

                Text {
                    text: Math.round(Brightness.fraction * 100) + "%"
                    color: Theme.hexToRgba(Theme.foreground, 0.6)
                    font.pixelSize: 11
                    font.family: "Departure Mono"
                    Layout.minimumWidth: 34
                    horizontalAlignment: Text.AlignRight
                }
            }
        }

        // ══ DETAIL ═════════════════════════════════════════════
        ColumnLayout {
            id: detailPane
            Layout.fillWidth: true
            spacing: 8
            visible: popup.detail !== ""

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Item {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32

                    Rectangle {
                        anchors.fill: parent
                        radius: 8
                        color: backHover.hovered
                            ? Theme.hexToRgba(Theme.foreground, 0.09)
                            : "transparent"
                        Behavior on color { ColorAnimation { duration: 100 } }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "󰅁"
                        font.pixelSize: 16
                        font.family: "Symbols Nerd Font"
                        color: backHover.hovered
                            ? Theme.foreground
                            : Theme.hexToRgba(Theme.foreground, 0.6)
                        Behavior on color { ColorAnimation { duration: 100 } }
                    }

                    HoverHandler { id: backHover }
                    TapHandler { onTapped: popup.detail = "" }
                }

                Text {
                    Layout.fillWidth: true
                    text: popup.detailTitle
                    color: Theme.foreground
                    font.pixelSize: 14
                    font.bold: true
                }

                Text {
                    text: popup.detail === "wifi"
                        ? (Net.wifiEnabled ? "On" : "Off")
                        : popup.detail === "bluetooth"
                        ? (BtService.enabled ? "On" : "Off")
                        : ""
                    visible: text !== ""
                    color: Theme.hexToRgba(Theme.foreground, 0.5)
                    font.pixelSize: 11
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Theme.hexToRgba(Theme.foreground, 0.08)
            }

            // ---- wifi list ----
            ListView {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(contentHeight, 4 * 52)
                visible: popup.detail === "wifi"
                clip: true
                interactive: contentHeight > height
                model: popup.detail === "wifi" ? Net.networks : []

                Text {
                    anchors.centerIn: parent
                    visible: parent.count === 0
                    text: Net.wifiEnabled ? "Scanning…" : "Wi-Fi is off"
                    color: Theme.hexToRgba(Theme.foreground, 0.4)
                    font.pixelSize: 12
                }

                delegate: NetworkRow {
                    required property var modelData
                    width: ListView.view.width
                    network: modelData
                }
            }

            // ---- bluetooth list ----
            ListView {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(contentHeight, 4 * 56)
                visible: popup.detail === "bluetooth"
                clip: true
                interactive: contentHeight > height
                model: popup.detail === "bluetooth" ? BtService.devices : []

                Text {
                    anchors.centerIn: parent
                    visible: parent.count === 0
                    text: BtService.enabled ? "Searching…" : "Bluetooth is off"
                    color: Theme.hexToRgba(Theme.foreground, 0.4)
                    font.pixelSize: 12
                }

                delegate: BluetoothRow {
                    required property var modelData
                    width: ListView.view.width
                    device: modelData
                }
            }

            // ---- night light temperature ----
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                visible: popup.detail === "nightlight"

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    SliderWidget {
                        Layout.fillWidth: true
                        alwaysExpanded: true
                        fontSize: 18
                        icon: "󰽥"
                        iconColor: Theme.foreground
                        fillColor: Theme.color3

                        value: 1 - (NightLight.temperature - NightLight.minTemperature)
                            / (NightLight.maxTemperature - NightLight.minTemperature)

                        onSliderMoved: (v) => NightLight.setTemperature(
                            NightLight.maxTemperature
                            - v * (NightLight.maxTemperature - NightLight.minTemperature))
                    }

                    Text {
                        text: NightLight.temperature + "K"
                        color: Theme.hexToRgba(Theme.foreground, 0.6)
                        font.pixelSize: 11
                        font.family: "Departure Mono"
                        Layout.minimumWidth: 44
                        horizontalAlignment: Text.AlignRight
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: {
                        const t = NightLight.temperature
                        if (t >= 6200) return "Neutral — no visible tint"
                        if (t >= 5400) return "Very subtle"
                        if (t >= 4800) return "Mild warmth"
                        if (t >= 4200) return "Warm"
                        if (t >= 3400) return "Strong"
                        return "Very strong"
                    }
                    color: Theme.hexToRgba(Theme.foreground, 0.4)
                    font.pixelSize: 10
                }
            }
        }
    }
}
