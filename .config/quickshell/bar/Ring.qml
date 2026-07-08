import qs
import QtQuick
import QtQuick.Shapes

// Progress ring. Same public API as the old Canvas version (value, thickness,
// activeColor, centered content) but drawn with Shapes so the fill animation
// renders on the GPU instead of rasterizing on the CPU every frame.
Item {
    id: root

    property real value: 0                  // 0..1
    property real thickness: 3
    property real warnThreshold: 0.9

    property color normalColor: Theme.color5
    property color warnColor: Theme.color1
    property color trackColor: Theme.hexToRgba(Theme.foreground, 0.15)

    readonly property color activeColor: value >= warnThreshold ? warnColor : normalColor

    default property alias content: contentSlot.data

    // smooth fill; drives the arc's sweepAngle binding below
    Behavior on value {
        NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
    }

    readonly property real _cx: width / 2
    readonly property real _cy: height / 2
    readonly property real _r: Math.min(width, height) / 2 - thickness / 2

    Shape {
        anchors.fill: parent
        antialiasing: true
        preferredRendererType: Shape.CurveRenderer   // GPU path (Qt 6.6+)

        // track
        ShapePath {
            fillColor: "transparent"
            strokeColor: root.trackColor
            strokeWidth: root.thickness
            capStyle: ShapePath.FlatCap

            PathAngleArc {
                centerX: root._cx
                centerY: root._cy
                radiusX: root._r
                radiusY: root._r
                startAngle: -90
                sweepAngle: 360
            }
        }

        // progress
        ShapePath {
            fillColor: "transparent"
            strokeColor: root.activeColor
            strokeWidth: root.thickness
            capStyle: ShapePath.RoundCap

            Behavior on strokeColor { ColorAnimation { duration: 200 } }

            PathAngleArc {
                centerX: root._cx
                centerY: root._cy
                radiusX: root._r
                radiusY: root._r
                startAngle: -90
                sweepAngle: 360 * Math.max(0, Math.min(1, root.value))
            }
        }
    }

    // centered content (e.g. the icon in SysMonitor)
    Item {
        id: contentSlot
        anchors.fill: parent
    }
}
