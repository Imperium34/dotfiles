import qs
import qs.widgets
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
    implicitWidth: widget.implicitWidth
    implicitHeight: widget.implicitHeight

    property int current: 0
    property int maximum: 1
    property real sliderValue: widget.expanded ? sliderValue : percent / 100

    readonly property int percent: maximum > 0
        ? Math.round(current / maximum * 100) : 0

    readonly property string backlightIcon: {
        if (percent < 33) return "";
        if (percent < 66) return "󰖨";
        return "󰖨";
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

    Process {
        id: getProc
        command: ["brightnessctl", "get"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: current = parseInt(this.text.trim()) || 0
        }
    }

    Process {
        id: maxProc
        command: ["brightnessctl", "max"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: maximum = parseInt(this.text.trim()) || 1
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            getProc.running = true
            maxProc.running = true
        }
    }
}
