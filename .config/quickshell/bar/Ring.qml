import qs
import QtQuick

Item {
    id: root

    property real value: 0
    property real thickness: 3
    property color trackColor: Theme.hexToRgba(Theme.foreground, 0.15)
    property color fillColor: Theme.color5
    property color warnColor: "#e0405a"
    property real warnThreshold: 0.9

    readonly property color activeColor: value >= warnThreshold ? warnColor : fillColor

    Behavior on value {
        NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
    }
    onActiveColorChanged: canvas.requestPaint()
    onValueChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()

            const cx = width / 2
            const cy = height / 2
            const r = Math.min(width, height) / 2 - root.thickness / 2
            const start = -Math.PI / 2
            const end = start + root.value * 2 * Math.PI

            ctx.beginPath()
            ctx.arc(cx, cy, r, 0, 2 * Math.PI)
            ctx.lineWidth = root.thickness
            ctx.strokeStyle = root.trackColor
            ctx.stroke()

            if (root.value > 0) {
                ctx.beginPath()
                ctx.arc(cx, cy, r, start, end)
                ctx.lineWidth = root.thickness
                ctx.strokeStyle = root.activeColor
                ctx.lineCap = "round"
                ctx.stroke()
            }
        }
    }
}
