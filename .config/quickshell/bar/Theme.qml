pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string background: adapter.background
    readonly property string foreground: adapter.foreground
    readonly property string color0:  adapter.color0
    readonly property string color1:  adapter.color1
    readonly property string color2:  adapter.color2
    readonly property string color3:  adapter.color3
    readonly property string color4:  adapter.color4
    readonly property string color5:  adapter.color5
    readonly property string color6:  adapter.color6
    readonly property string color7:  adapter.color7
    readonly property string color8:  adapter.color8
    readonly property string color9:  adapter.color9
    readonly property string color10: adapter.color10
    readonly property string color11: adapter.color11
    readonly property string color12: adapter.color12
    readonly property string color13: adapter.color13
    readonly property string color14: adapter.color14
    readonly property string color15: adapter.color15

    FileView {
        id: colorFile
        path: Qt.resolvedUrl("./theme.json")
        watchChanges: true
        blockLoading: true
        onFileChanged: reload()

        JsonAdapter {
            id: adapter
            property string background: "#000000"
            property string foreground: "#ffffff"
            property string color0:  "#000000"
            property string color1:  "#000000"
            property string color2:  "#000000"
            property string color3:  "#000000"
            property string color4:  "#000000"
            property string color5:  "#000000"
            property string color6:  "#000000"
            property string color7:  "#000000"
            property string color8:  "#000000"
            property string color9:  "#000000"
            property string color10: "#000000"
            property string color11: "#000000"
            property string color12: "#000000"
            property string color13: "#000000"
            property string color14: "#000000"
            property string color15: "#000000"
        }
    }

    function hexToRgba(hex, alpha) {
        return Qt.rgba(
            parseInt(hex.slice(1, 3), 16) / 255,
            parseInt(hex.slice(3, 5), 16) / 255,
            parseInt(hex.slice(5, 7), 16) / 255,
            alpha
        )
    }

    function surfaceAlpha(base) {
        return PowerState.blurEnabled ? base : Math.min(1.0, base + 0.15)
    }
}
