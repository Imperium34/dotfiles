import qs
import qs.widgets
import qs.components
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

BasePopup {
    id: popup

    implicitWidth: 340
    implicitHeight: layoutCol.implicitHeight + 32

    // ── STATE ──────────────────────────────────────────────────
    property int currentMonth: 0
    property int currentYear: 0
    property string todayString: ""
    property string selectedDateString: ""

    property var weatherData: ({ "temp": "--", "icon": "󰖐", "high": null, "low": null })
    property var eventsData: []
    property string loadError: ""
    property bool loading: false

    readonly property var selectedDayEvents: eventsData.filter(e => e.date === selectedDateString)

    readonly property var monthNames: ["January", "February", "March", "April", "May", "June",
                                       "July", "August", "September", "October", "November", "December"]
    readonly property var dayNames: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

    property bool showSettings: false
    property bool addingEvent: false

    readonly property real cellSize: (popup.implicitWidth - 32 - 12) / 7

    readonly property int firstDayOffset: {
        const day = new Date(popup.currentYear, popup.currentMonth, 1).getDay()
        return day === 0 ? 6 : day - 1
    }

    readonly property bool onCurrentMonth: {
        const now = new Date()
        return popup.currentMonth === now.getMonth() && popup.currentYear === now.getFullYear()
    }

    // ── DATE HELPERS ───────────────────────────────────────────
    function resetToToday() {
        const now = new Date()
        popup.currentMonth = now.getMonth()
        popup.currentYear = now.getFullYear()
        popup.todayString = Qt.formatDateTime(now, "yyyy-MM-dd")
        popup.selectedDateString = popup.todayString
    }

    function changeMonth(delta) {
        let m = popup.currentMonth + delta
        let y = popup.currentYear
        if (m > 11) { m = 0; y++ }
        if (m < 0)  { m = 11; y-- }
        popup.currentMonth = m
        popup.currentYear = y
    }

    function cellDate(index) {
        return new Date(popup.currentYear, popup.currentMonth, 1 - popup.firstDayOffset + index)
    }

    Component.onCompleted: popup.resetToToday()

    // ── DATA ───────────────────────────────────────────────────
    FileView {
        id: weatherFile
        path: Qt.resolvedUrl("./weather.json")

        JsonAdapter {
            id: weatherSettings
            property string lat: "41.02"
            property string lon: "28.58"
        }
    }

    FileView {
        id: cacheFile
        path: Quickshell.env("HOME") + "/.cache/quickshell/calendar.json"
        onLoaded: popup.ingest(text())
    }

    function ingest(raw) {
        try {
            const parsed = JSON.parse((raw || "").trim())
            if (parsed.weather) popup.weatherData = parsed.weather
            if (parsed.events)  popup.eventsData = parsed.events
            popup.loadError = parsed.error || ""
        } catch (e) {
        }
    }

    onAnimInChanged: {
        if (animIn) {
            popup.resetToToday()
            popup.showSettings = false
            popup.addingEvent = false
            popup.loading = true
            backendProc.running = true
        }
    }

    Process {
        id: backendProc
        command: [
            "/usr/bin/python3",
            Quickshell.env("HOME") + "/.config/quickshell/scripts/calendar-backend.py",
            weatherSettings.lat,
            weatherSettings.lon
        ]
        onRunningChanged: if (!running) popup.loading = false
        stdout: StdioCollector {
            onStreamFinished: popup.ingest(text)
        }
    }

    Process {
        id: addEventProc
        command: []
        stdout: StdioCollector {
            onStreamFinished: {
                let ok = false
                try { ok = JSON.parse(text.trim()).ok === true } catch (e) {}
                if (ok) {
                    popup.addingEvent = false
                    addInput.text = ""
                    popup.loading = true
                    backendProc.running = true
                } else {
                    popup.loadError = "add-failed"
                }
            }
        }
    }

    function submitEvent() {
        const t = addInput.text.trim()
        if (t === "") return
        const when = Qt.formatDateTime(new Date(popup.selectedDateString), "d MMMM yyyy")
        addEventProc.command = [
            "/usr/bin/python3",
            Quickshell.env("HOME") + "/.config/quickshell/scripts/calendar-backend.py",
            "add", t + " " + when
        ]
        addEventProc.running = true
    }

    HyprlandFocusGrab {
        id: addFocusGrab
        windows: [popup]
        active: popup.addingEvent
        onCleared: popup.addingEvent = false
    }

    // ── UI ─────────────────────────────────────────────────────
    ColumnLayout {
        id: layoutCol
        anchors { top: parent.top; left: parent.left; right: parent.right; margins: 16 }
        spacing: 12

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            radius: 8
            color: weatherHover.hovered ? Theme.hexToRgba(Theme.foreground, 0.08) : "transparent"
            Behavior on color { ColorAnimation { duration: 150 } }

            HoverHandler { id: weatherHover }

            RowLayout {
                anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                spacing: 8

                Text {
                    text: popup.weatherData.icon
                    color: Theme.color4
                    font.pixelSize: 22
                    font.family: "Symbols Nerd Font"
                }

                Text {
                    text: popup.weatherData.temp + "°C"
                    color: Theme.foreground
                    font.pixelSize: 16
                    font.family: "Departure Mono"
                    font.bold: true
                }

                Text {
                    visible: popup.weatherData.high !== null && popup.weatherData.high !== undefined
                    text: "󰁝" + popup.weatherData.high + "  󰁅" + popup.weatherData.low
                    color: Theme.hexToRgba(Theme.foreground, 0.45)
                    font.pixelSize: 11
                    font.family: "Departure Mono"
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "󰒓"
                    color: Theme.hexToRgba(Theme.foreground, popup.showSettings ? 0.8 : 0.3)
                    font.pixelSize: 14
                    font.family: "Symbols Nerd Font"
                }
            }

            TapHandler { onTapped: popup.showSettings = !popup.showSettings }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            clip: true
            visible: opacity > 0
            opacity: popup.showSettings ? 1 : 0
            implicitHeight: popup.showSettings ? 40 : 0
            Behavior on implicitHeight { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text { text: "Lat:"; color: Theme.foreground; font.pixelSize: 12 }
                TextInput {
                    id: latInput
                    Layout.fillWidth: true
                    text: weatherSettings.lat
                    color: acceptableInput ? Theme.color5 : Theme.color3
                    font.pixelSize: 12
                    font.family: "Departure Mono"
                    validator: DoubleValidator { bottom: -90; top: 90; decimals: 6; notation: DoubleValidator.StandardNotation }
                }

                Text { text: "Lon:"; color: Theme.foreground; font.pixelSize: 12 }
                TextInput {
                    id: lonInput
                    Layout.fillWidth: true
                    text: weatherSettings.lon
                    color: acceptableInput ? Theme.color5 : Theme.color3
                    font.pixelSize: 12
                    font.family: "Departure Mono"
                    validator: DoubleValidator { bottom: -180; top: 180; decimals: 6; notation: DoubleValidator.StandardNotation }
                }

                Rectangle {
                    width: 40; height: 24; radius: 6
                    color: (latInput.acceptableInput && lonInput.acceptableInput)
                        ? Theme.hexToRgba(Theme.color5, 0.7)
                        : Theme.hexToRgba(Theme.foreground, 0.15)

                    Text {
                        anchors.centerIn: parent
                        text: "Save"
                        font.pixelSize: 11
                        font.bold: true
                        color: Theme.background
                    }

                    TapHandler {
                        enabled: latInput.acceptableInput && lonInput.acceptableInput
                        onTapped: {
                            weatherSettings.lat = latInput.text
                            weatherSettings.lon = lonInput.text
                            weatherFile.writeAdapter()
                            popup.showSettings = false
                            popup.loading = true
                            backendProc.running = true
                        }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.hexToRgba(Theme.foreground, 0.08) }
        }

        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.hexToRgba(Theme.foreground, 0.08) }

        RowLayout {
            Layout.fillWidth: true

            Item {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32

                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    color: prevHover.hovered ? Theme.hexToRgba(Theme.foreground, 0.09) : "transparent"
                    Behavior on color { ColorAnimation { duration: 100 } }
                }

                Text {
                    anchors.centerIn: parent
                    text: "󰅁"
                    color: Theme.hexToRgba(Theme.foreground, 0.7)
                    font.pixelSize: 18
                    font.family: "Symbols Nerd Font"
                }

                HoverHandler { id: prevHover }
                TapHandler { onTapped: popup.changeMonth(-1) }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: popup.monthNames[popup.currentMonth] + " " + popup.currentYear
                    color: Theme.foreground
                    font.pixelSize: 14
                    font.bold: true
                }

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: "back to today"
                    color: Theme.hexToRgba(Theme.color5, todayHover.hovered ? 1 : 0.6)
                    font.pixelSize: 9
                    visible: !popup.onCurrentMonth
                }

                HoverHandler { id: todayHover }
                TapHandler { onTapped: popup.resetToToday() }
            }

            Item {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32

                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    color: nextHover.hovered ? Theme.hexToRgba(Theme.foreground, 0.09) : "transparent"
                    Behavior on color { ColorAnimation { duration: 100 } }
                }

                Text {
                    anchors.centerIn: parent
                    text: "󰅂"
                    color: Theme.hexToRgba(Theme.foreground, 0.7)
                    font.pixelSize: 18
                    font.family: "Symbols Nerd Font"
                }

                HoverHandler { id: nextHover }
                TapHandler { onTapped: popup.changeMonth(1) }
            }
        }

        GridLayout {
            Layout.alignment: Qt.AlignHCenter
            columns: 7
            columnSpacing: 2

            Repeater {
                model: popup.dayNames
                Text {
                    Layout.preferredWidth: popup.cellSize
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    color: Theme.hexToRgba(Theme.foreground, 0.4)
                    font.pixelSize: 11
                }
            }
        }

        GridLayout {
            Layout.alignment: Qt.AlignHCenter
            columns: 7
            columnSpacing: 2
            rowSpacing: 2

            Repeater {
                model: 42

                delegate: Rectangle {
                    id: cell

                    readonly property date thisDate: popup.cellDate(index)
                    readonly property string thisDateStr: Qt.formatDateTime(thisDate, "yyyy-MM-dd")
                    readonly property int dayNum: thisDate.getDate()
                    readonly property bool inMonth: thisDate.getMonth() === popup.currentMonth

                    readonly property bool isToday: thisDateStr === popup.todayString
                    readonly property bool isSelected: thisDateStr === popup.selectedDateString
                    readonly property bool hasEvent: popup.eventsData.some(e => e.date === cell.thisDateStr)

                    Layout.preferredWidth: popup.cellSize
                    Layout.preferredHeight: popup.cellSize
                    radius: width / 2

                    color: cell.isSelected
                        ? Theme.hexToRgba(Theme.color5, 0.3)
                        : (dayHover.hovered ? Theme.hexToRgba(Theme.foreground, 0.08) : "transparent")
                    border.color: cell.isToday ? Theme.color5 : "transparent"
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 100 } }

                    HoverHandler { id: dayHover }
                    TapHandler {
                        onTapped: {
                            popup.selectedDateString = cell.thisDateStr
                            if (!cell.inMonth) {
                                popup.currentMonth = cell.thisDate.getMonth()
                                popup.currentYear = cell.thisDate.getFullYear()
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: cell.dayNum
                        color: !cell.inMonth
                            ? Theme.hexToRgba(Theme.foreground, 0.25)
                            : (cell.isSelected ? Theme.foreground
                                               : (cell.isToday ? Theme.color5 : Theme.hexToRgba(Theme.foreground, 0.8)))
                        font.pixelSize: 13
                        font.bold: cell.isToday || cell.isSelected
                    }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 4
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 4
                        height: 4
                        radius: 2
                        color: cell.isToday ? Theme.foreground : Theme.color5
                        opacity: cell.inMonth ? 1 : 0.4
                        visible: cell.hasEvent
                    }
                }
            }
        }

        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.hexToRgba(Theme.foreground, 0.08) }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    Layout.fillWidth: true
                    color: Theme.hexToRgba(Theme.foreground, 0.5)
                    font.pixelSize: 12
                    elide: Text.ElideRight
                    text: {
                        if (popup.loadError === "no-auth")      return "Calendar not connected"
                        if (popup.loadError === "fetch-failed") return "Couldn't reach Google Calendar"
                        if (popup.loadError === "add-failed")   return "Couldn't add that event"
                        if (popup.selectedDayEvents.length > 0)
                            return Qt.formatDateTime(new Date(popup.selectedDateString), "d MMMM")
                        return "Nothing scheduled"
                    }
                }

                Text {
                    text: "󰑐"
                    color: Theme.hexToRgba(Theme.foreground, 0.3)
                    font.pixelSize: 11
                    font.family: "Symbols Nerd Font"
                    visible: popup.loading
                    RotationAnimation on rotation {
                        running: popup.loading
                        loops: Animation.Infinite
                        from: 0; to: 360; duration: 1200
                    }
                }
            }

            ListView {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(contentHeight, 132)
                visible: popup.selectedDayEvents.length > 0
                clip: true
                spacing: 4
                model: popup.selectedDayEvents

                delegate: RowLayout {
                    width: ListView.view.width
                    height: 18
                    spacing: 8

                    Rectangle {
                        Layout.preferredWidth: 2
                        Layout.preferredHeight: 14
                        radius: 1
                        color: modelData.allDay ? Theme.color3 : Theme.color4
                    }

                    Text {
                        text: modelData.time
                        color: Theme.hexToRgba(Theme.foreground, 0.7)
                        font.pixelSize: 11
                        font.family: "Departure Mono"
                    }

                    Text {
                        Layout.fillWidth: true
                        text: modelData.title
                        color: Theme.foreground
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: popup.addingEvent ? "󰅖" : "󰐕"
                    color: Theme.hexToRgba(Theme.foreground, 0.5)
                    font.pixelSize: 14
                    font.family: "Symbols Nerd Font"
                    TapHandler {
                        onTapped: {
                            popup.addingEvent = !popup.addingEvent
                            if (popup.addingEvent) addInput.forceActiveFocus()
                            else addInput.text = ""
                        }
                    }
                }

                TextInput {
                    id: addInput
                    Layout.fillWidth: true
                    visible: popup.addingEvent
                    color: Theme.foreground
                    font.pixelSize: 12
                    clip: true
                    selectByMouse: true
                    selectionColor: Theme.hexToRgba(Theme.color4, 0.4)

                    Keys.onReturnPressed: popup.submitEvent()
                    Keys.onEscapePressed: { popup.addingEvent = false; text = "" }

                    Text {
                        anchors.fill: parent
                        text: "Dinner 7pm"
                        color: Theme.hexToRgba(Theme.foreground, 0.3)
                        font.pixelSize: 12
                        visible: addInput.text === ""
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Text {
                    text: "Add event"
                    color: Theme.hexToRgba(Theme.foreground, 0.4)
                    font.pixelSize: 11
                    visible: !popup.addingEvent
                }
            }
        }
    }
}
