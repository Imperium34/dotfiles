import qs
import QtQuick
import QtQuick.Layouts

BasePopup {
    id: root

    property string title: ""

    property alias model: listView.model
    property Component rowDelegate: null
    property int rowHeight: 52
    property int maxVisible: 6
    property int maxListHeight: maxVisible * rowHeight
    property int maxPopupHeight: 0
    property bool pinMaxHeight: false
    property string emptyText: ""

    property bool toggleOn: false
    property bool toggleInteractive: true
    property color toggleOnColor: Theme.color5
    property color toggleTrackColor: toggleOn ? toggleOnColor : Theme.hexToRgba(Theme.foreground, 0.2)
    property color toggleThumbColor: Theme.background
    signal toggled()

    property string footerIcon: ""
    property string footerText: ""
    property bool footerVisible: footerText !== ""
    signal footerActivated()

    implicitWidth: 320
    readonly property int _contentHeight: headerRow.height + listView.height + footerItem.height
    implicitHeight: root.pinMaxHeight && root.maxPopupHeight > 0
        ? root.maxPopupHeight
        : (root.maxPopupHeight > 0 ? Math.min(_contentHeight, root.maxPopupHeight) : _contentHeight)

    RowLayout {
        id: headerRow
        anchors { top: parent.top; left: parent.left; right: parent.right }
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        height: 52

        Text {
            text: root.title
            color: Theme.foreground
            font.pixelSize: 15
            font.bold: true
            Layout.fillWidth: true
        }

        Item {
            width: 44
            height: 26

            Rectangle {
                anchors.fill: parent
                radius: 13
                color: root.toggleTrackColor
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            Rectangle {
                width: 20
                height: 20
                radius: 10
                color: root.toggleThumbColor
                anchors.verticalCenter: parent.verticalCenter
                x: root.toggleOn ? parent.width - width - 3 : 3
                Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            }

            TapHandler {
                enabled: root.toggleInteractive
                onTapped: root.toggled()
            }
        }
    }

    Rectangle {
        id: headerDivider
        anchors.top: headerRow.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        height: 1
        color: Theme.hexToRgba(Theme.foreground, 0.08)
    }

    ListView {
        id: listView
        anchors.top: headerDivider.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.pinMaxHeight ? root.maxListHeight : Math.min(contentHeight, root.maxListHeight)
        clip: true
        interactive: contentHeight > height
        delegate: root.rowDelegate

        Text {
            anchors.centerIn: parent
            text: root.emptyText
            color: Theme.hexToRgba(Theme.foreground, 0.4)
            font.pixelSize: 13
            visible: listView.count === 0
        }
    }

    Rectangle {
        id: footerDivider
        anchors.top: listView.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        height: root.footerVisible ? 1 : 0
        visible: root.footerVisible
        color: Theme.hexToRgba(Theme.foreground, 0.08)
    }

    Item {
        id: footerItem
        anchors.top: footerDivider.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.footerVisible ? 44 : 0
        visible: root.footerVisible

        HoverHandler { id: footerHover }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 4
            radius: 10
            color: footerHover.hovered
                ? Theme.hexToRgba(Theme.foreground, 0.07)
                : "transparent"
            Behavior on color { ColorAnimation { duration: 100 } }
        }

        RowLayout {
            anchors.centerIn: parent
            spacing: 6

            Text {
                text: root.footerIcon
                visible: root.footerIcon !== ""
                color: Theme.hexToRgba(Theme.foreground, 0.6)
                font.pixelSize: 14
                font.family: "Symbols Nerd Font"
            }

            Text {
                text: root.footerText
                color: Theme.hexToRgba(Theme.foreground, 0.6)
                font.pixelSize: 13
            }
        }

        TapHandler {
            onTapped: root.footerActivated()
        }
    }
}
