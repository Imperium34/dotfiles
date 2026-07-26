import qs
import QtQuick
import QtQuick.Controls

Item {
    id: root

    // ---- data ----
    property alias model: listView.model
    property Component delegate: null

    // ---- optional header row (e.g. Clipboard's "Clear History") ----
    property Component header: null
    property int headerHeight: 36
    property string headerAccentColor: Theme.color4

    // ---- sizing ----
    property int rowHeight: 40
    property alias spacing: listView.spacing

    // ---- selection state ----
    property int selectedIndex: 0
    readonly property int minIndex: 0
    readonly property int maxIndex: root.header
        ? listView.count
        : Math.max(listView.count - 1, 0)
    readonly property int _headerOffset: root.header ? 1 : 0

    property string accentColor: Theme.color4
    property alias emptyText: emptyLabel.text

    ListView {
        id: listView
        anchors.fill: parent
        clip: true
        spacing: 2
        currentIndex: root.selectedIndex
        onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }

        header: root.header ? headerWrap : null

        Component {
            id: headerWrap
            Item {
                id: headerRoot
                width: listView.width
                height: root.headerHeight
                readonly property bool selected: root.selectedIndex === 0

                HoverHandler {
                    onHoveredChanged: if (hovered) root.selectedIndex = 0
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    color: headerRoot.selected
                        ? Theme.hexToRgba(root.headerAccentColor, 0.7)
                        : "transparent"
                    Behavior on color { ColorAnimation { duration: 100 } }
                }

                Loader {
                    anchors.fill: parent
                    sourceComponent: root.header
                    onLoaded: if (item) item.selected = Qt.binding(() => headerRoot.selected)
                }
            }
        }

        delegate: Item {
            id: rowWrap
            required property var modelData
            required property int index
            width: listView.width
            height: root.rowHeight

            readonly property int displayIndex: index + root._headerOffset
            readonly property bool selected: root.selectedIndex === rowWrap.displayIndex

            HoverHandler {
                onHoveredChanged: if (hovered) root.selectedIndex = rowWrap.displayIndex
            }

            Rectangle {
                anchors.fill: parent
                radius: 8
                color: rowWrap.selected
                    ? Theme.hexToRgba(root.accentColor, 0.7)
                    : "transparent"
                Behavior on color { ColorAnimation { duration: 100 } }
            }

            Loader {
                id: rowLoader
                anchors.fill: parent
                sourceComponent: root.delegate
                onLoaded: {
                    if (item) {
                        item.modelData = rowWrap.modelData
                        item.index = rowWrap.displayIndex
                        item.selected = Qt.binding(() => rowWrap.selected)
                    }
                }
            }
        }

        Text {
            id: emptyLabel
            anchors.centerIn: parent
            color: Theme.hexToRgba(Theme.foreground, 0.4)
            font.pixelSize: 13
            visible: listView.count === 0 && text !== ""
        }
    }
}
