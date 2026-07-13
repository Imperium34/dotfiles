import qs
import qs.widgets
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
    id: backlightRoot
    implicitWidth: widget.implicitWidth
    implicitHeight: widget.implicitHeight

    property string device: ""
    property int current: 0
    property int maximum: 1
    property real sliderValue: percent / 100

    readonly property int percent: maximum > 0
        ? Math.round(current / maximum * 100) : 0

    readonly property string backlightIcon: {
        if (percent < 33) return "󰃞";
        if (percent < 66) return "󰃟";
        return "󰃠";
    }

    Binding {
        target: backlightRoot
        property: "sliderValue"
        value: backlightRoot.percent / 100
        when: !widget.expanded
    }

    Process {
        id: deviceResolver
        command: ["bash", "-c", "ls /sys/class/backlight | head -1"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const d = text.trim()
                if (d) backlightRoot.device = d
            }
        }
    }

    FileView {
        id: brightnessFile
        path: backlightRoot.device
            ? "/sys/class/backlight/" + backlightRoot.device + "/brightness"
            : ""
    }

    FileView {
        id: maxBrightnessFile
        path: backlightRoot.device
            ? "/sys/class/backlight/" + backlightRoot.device + "/max_brightness"
            : ""
    }

    Process {
        id: brightnessSet
        command: ["/usr/bin/brightnessctl", "-q", "set", "0%"]
    }

    SliderWidget {
        id: widget
        icon: backlightIcon
        value: sliderValue
        onSliderMoved: (v) => {
            sliderValue = v
            if (!brightnessSet.running) {
                brightnessSet.command = ["/usr/bin/brightnessctl", "-q", "set", Math.round(v * 100) + "%"]
                brightnessSet.running = true
            }
        }
    }

    Timer {
        interval: 2000
        running: backlightRoot.device !== ""
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            backlightRoot.current = parseInt(brightnessFile.text().trim()) || backlightRoot.current
            backlightRoot.maximum = parseInt(maxBrightnessFile.text().trim()) || backlightRoot.maximum
            brightnessFile.reload()
            maxBrightnessFile.reload()
        }
    }
}
