import qs
import qs.widgets
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts

Item {
    implicitWidth: widget.implicitWidth
    implicitHeight: widget.implicitHeight

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var audio: sink ? sink.audio : null
    readonly property bool muted: audio ? audio.muted : false
    readonly property int volume: audio ? Math.round(audio.volume * 100) : 0

    readonly property string audioIcon: {
        if (!audio || muted) return "󰝟"
        if (volume == 0)     return "󰝟"
        if (volume < 34)     return ""
        if (volume < 67)     return ""
        return ""
    }

    SliderWidget {
        id: widget
        icon: audioIcon
        value: audio ? audio.volume : 0
        iconColor: muted ? Theme.color1 : Theme.foreground
        onSliderMoved: (v) => {
            if (audio) audio.volume = v
        }
    }

    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: if (audio) audio.muted = !audio.muted
    }

}
