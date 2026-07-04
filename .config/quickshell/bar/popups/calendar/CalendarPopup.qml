import "../../widgets"
import qs
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

BasePopup {
    id: popup

    implicitWidth: 340
    implicitHeight: layoutCol.implicitHeight + 32

    // ── STATE ──────────────────────────────────────────────────
    property int currentMonth: new Date().getMonth()
    property int currentYear: new Date().getFullYear()
    property string selectedDateString: Qt.formatDateTime(new Date(), "yyyy-MM-dd")
    
    property var weatherData: {"temp": "--", "icon": "󰖐"}
    property var eventsData: []
    property var selectedDayEvents: eventsData.filter(e => e.date === selectedDateString)

    readonly property var monthNames: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    readonly property var dayNames: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

    property bool showSettings: false

    // ── DATA PERSISTENCE ───────────────────────────────────────
    FileView {
        id: weatherFile
        path: Qt.resolvedUrl("./weather.json")

        JsonAdapter {
            id: weatherSettings
            property string lat: "41.02"
            property string lon: "28.58"
        }
    }

    // ── DATA FETCHING ──────────────────────────────────────────
    onAnimInChanged: {
        if (animIn) backendProc.running = true
    }

    Process {
        id: backendProc
        command: [
            "/usr/bin/python3", 
            Quickshell.env("HOME") + "/.config/quickshell/scripts/calendar-backend.py",
            weatherSettings.lat,
            weatherSettings.lon
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(text.trim())
                    popup.weatherData = parsed.weather || popup.weatherData
                    popup.eventsData = parsed.events || []
                } catch (e) { }
            }
        }
    }

    // ── CALENDAR LOGIC ─────────────────────────────────────────
    function getDaysInMonth(month, year) {
        return new Date(year, month + 1, 0).getDate()
    }

    function getFirstDayOffset(month, year) {
        let day = new Date(year, month, 1).getDay()
        return day === 0 ? 6 : day - 1
    }

    function changeMonth(delta) {
        let m = currentMonth + delta
        let y = currentYear
        if (m > 11) { m = 0; y++ }
        if (m < 0) { m = 11; y-- }
        currentMonth = m
        currentYear = y
    }

    // ── UI ─────────────────────────────────────────────────────
    Rectangle {
        id: card
        anchors.fill: parent
        radius: 16
        color: Theme.hexToRgba(Theme.background, 0.92)
        border.color: Theme.hexToRgba(Theme.foreground, 0.1)
        border.width: 1
        clip: true

        opacity: popup.animIn ? 1 : 0
        scale: popup.animIn ? 1 : 0.95
        transformOrigin: Item.Top
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on scale   { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        ColumnLayout {
            id: layoutCol
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 16 }
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                HoverHandler { id: weatherHover }
                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    radius: 8
                    color: weatherHover.hovered ? Theme.hexToRgba(Theme.foreground, 0.08) : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        
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
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "󰒓" // Settings gear icon
                            color: Theme.hexToRgba(Theme.foreground, popup.showSettings ? 0.8 : 0.3)
                            font.pixelSize: 14
                            font.family: "Symbols Nerd Font"
                        }
                    }
                    TapHandler { onTapped: popup.showSettings = !popup.showSettings }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                visible: opacity > 0
                opacity: popup.showSettings ? 1 : 0
                implicitHeight: popup.showSettings ? 40 : 0
                clip: true
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
                        color: Theme.color5
                        font.pixelSize: 12
                        font.family: "Departure Mono"
                    }

                    Text { text: "Lon:"; color: Theme.foreground; font.pixelSize: 12 }
                    TextInput {
                        id: lonInput
                        Layout.fillWidth: true
                        text: weatherSettings.lon
                        color: Theme.color5
                        font.pixelSize: 12
                        font.family: "Departure Mono"
                    }

                    Rectangle {
                        width: 40; height: 24; radius: 6
                        color: Theme.hexToRgba(Theme.color5, 0.7)
                        Text { anchors.centerIn: parent; text: "Save"; font.pixelSize: 11; color: Theme.background; font.bold: true }
                        TapHandler {
                            onTapped: {
                                weatherSettings.lat = latInput.text
                                weatherSettings.lon = lonInput.text
                                weatherFile.writeAdapter()
                                popup.showSettings = false
                                backendProc.running = true
                            }
                        }
                    }
                }
                Rectangle { Layout.fillWidth: true; height: 1; color: Theme.hexToRgba(Theme.foreground, 0.08) }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.hexToRgba(Theme.foreground, 0.08) }

            RowLayout {
                Layout.fillWidth: true
                
                Text {
                    text: "󰅁"
                    color: Theme.hexToRgba(Theme.foreground, 0.7)
                    font.pixelSize: 18; font.family: "Symbols Nerd Font"
                    TapHandler { onTapped: popup.changeMonth(-1) }
                    HoverHandler { id: prevHover }
                    scale: prevHover.hovered ? 1.2 : 1
                    Behavior on scale { NumberAnimation { duration: 100 } }
                }
                
                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: popup.monthNames[popup.currentMonth] + " " + popup.currentYear
                    color: Theme.foreground
                    font.pixelSize: 14
                    font.bold: true
                }

                Text {
                    text: "󰅂"
                    color: Theme.hexToRgba(Theme.foreground, 0.7)
                    font.pixelSize: 18; font.family: "Symbols Nerd Font"
                    TapHandler { onTapped: popup.changeMonth(1) }
                    HoverHandler { id: nextHover }
                    scale: nextHover.hovered ? 1.2 : 1
                    Behavior on scale { NumberAnimation { duration: 100 } }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 7
                columnSpacing: 2

                Repeater {
                    model: popup.dayNames
                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData
                        color: Theme.hexToRgba(Theme.foreground, 0.4)
                        font.pixelSize: 11
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 7
                columnSpacing: 2
                rowSpacing: 2

                Repeater {
                    model: {
                        const days = popup.getDaysInMonth(popup.currentMonth, popup.currentYear)
                        const offset = popup.getFirstDayOffset(popup.currentMonth, popup.currentYear)
                        return days + offset
                    }

                    delegate: Rectangle {
                        readonly property int dayNum: index - popup.getFirstDayOffset(popup.currentMonth, popup.currentYear) + 1
                        readonly property bool isValidDay: dayNum > 0
                        
                        readonly property string thisDateStr: popup.currentYear + "-" + 
                            String(popup.currentMonth + 1).padStart(2, '0') + "-" + 
                            String(dayNum).padStart(2, '0')

                        readonly property bool isToday: thisDateStr === Qt.formatDateTime(new Date(), "yyyy-MM-dd")
                        readonly property bool isSelected: thisDateStr === popup.selectedDateString
                        readonly property bool hasEvent: popup.eventsData.some(e => e.date === thisDateStr)

                        Layout.fillWidth: true
                        Layout.preferredHeight: width
                        radius: width / 2
                        
                        color: isSelected && isValidDay ? Theme.hexToRgba(Theme.color5, 0.3) : (dayHover.hovered && isValidDay ? Theme.hexToRgba(Theme.foreground, 0.08) : "transparent")
                        border.color: isToday && isValidDay ? Theme.color5 : "transparent"
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 100 } }

                        HoverHandler { id: dayHover; enabled: isValidDay }
                        TapHandler { 
                            enabled: isValidDay
                            onTapped: popup.selectedDateString = thisDateStr
                        }

                        Text {
                            anchors.centerIn: parent
                            text: isValidDay ? dayNum : ""
                            color: isSelected ? Theme.foreground : (isToday ? Theme.color5 : Theme.hexToRgba(Theme.foreground, 0.8))
                            font.pixelSize: 13
                            font.bold: isToday || isSelected
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 4
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 4
                            height: 4
                            radius: 2
                            color: isToday ? Theme.foreground : Theme.color5
                            visible: isValidDay && hasEvent
                        }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.hexToRgba(Theme.foreground, 0.08) }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: popup.selectedDayEvents.length > 0 ? "Events for " + popup.selectedDateString : "No events"
                    color: Theme.hexToRgba(Theme.foreground, 0.5)
                    font.pixelSize: 12
                }

                Repeater {
                    model: popup.selectedDayEvents
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Rectangle {
                            width: 2
                            height: 14
                            color: Theme.color4
                            radius: 1
                        }
                        Text {
                            text: modelData.time
                            color: Theme.hexToRgba(Theme.foreground, 0.7)
                            font.pixelSize: 12
                            font.family: "Departure Mono"
                        }
                        Text {
                            Layout.fillWidth: true
                            text: modelData.title
                            color: Theme.foreground
                            font.pixelSize: 13
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }
}
