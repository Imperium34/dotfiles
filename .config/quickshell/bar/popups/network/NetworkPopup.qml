import "../../widgets"
import qs
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import QtQuick

ToggleListPopup {
    id: popup

    implicitWidth: 320
    title: "Wi-Fi"

    // Network's toggle has a third (rf-kill) state, so it overrides the colors
    toggleOn: Net.wifiEnabled
    toggleInteractive: !Net.hardwareBlocked
    toggleTrackColor: Net.hardwareBlocked
        ? Theme.hexToRgba(Theme.foreground, 0.15)
        : (Net.wifiEnabled ? Theme.color5 : Theme.hexToRgba(Theme.foreground, 0.2))
    toggleThumbColor: Net.hardwareBlocked
        ? Theme.hexToRgba(Theme.foreground, 0.4)
        : Theme.background
    onToggled: Net.wifiEnabled = !Net.wifiEnabled

    model: Net.networks
    rowHeight: 52
    maxVisible: 6

    // scan while the window is mapped, not just while animating open. Tying this
    // to animIn made scanning stop the instant close began, collapsing the list
    // and resizing the layer surface mid-fade -> the close flicker.
    onVisibleChanged: Net.scanning = root.visible

    emptyText: !Net.wifiEnabled
        ? "Wi-Fi is off"
        : Net.wifiDevice === null
        ? "No adapter"
        : "Scanning…"

    footerIcon: "󰒓"
    footerText: "Network Settings"
    onFooterActivated: {
        popup.close()
        nmtui.startDetached()
    }

    Process {
        id: nmtui
        command: ["/usr/bin/alacritty", "-e", "/usr/bin/nmtui"]
    }

    rowDelegate: Component {
        Item {
            required property int index
            width: ListView.view.width
            height: rowInstance.height
            readonly property var net: Net.networks[index]

            NetworkRow {
                id: rowInstance
                width: parent.width
                network: parent.net
            }
        }
    }
}
