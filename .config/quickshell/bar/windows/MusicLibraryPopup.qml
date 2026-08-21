import qs
import qs.services
import qs.components
import QtQuick
import QtQuick.Layouts

BaseExpandPopup {
    id: popup

    // ══ WINDOW ═══════════════════════════════════════════════════
    ipcTarget: "musiclibrary"
    placeholder: "Search Spotify..."

    implicitWidth: 480
    implicitHeight: 460

    // ══ VIEW STATE ═══════════════════════════════════════════════
    property string currentView: "search"
    property string playlistMode: "browse"

    readonly property var tabOrder: ["nowPlaying","queue" ,"search", "playlists"]
    readonly property var tabModel: [
        { key: "nowPlaying", label: "Now" },
        { key: "queue",      label: "Queue" },
        { key: "search",     label: "Search" },
        { key: "playlists",  label: "Playlists" }
    ]

    readonly property bool inPlaylistTracks:
        currentView === "playlists" && playlistMode === "tracks"

    showSearch: currentView === "search"

    // ══ KEYBOARD SELECTION ═══════════════════════════════════════
    readonly property var activeModel: {
        if (currentView === "search") return Spotify.searchResults
        if (currentView === "playlists") {
            return playlistMode === "tracks" ? Spotify.playlistTracks : Spotify.playlists
        }
        if (currentView === "queue") return Spotify.queueList
        return null
    }

    readonly property int activeListCount: activeModel ? activeModel.count : 0

    minIndex: 0
    maxIndex: Math.max(activeListCount - 1, 0)

    // ══ ACTIONS ══════════════════════════════════════════════════
    function switchTab(view) {
        currentView = view
        playlistMode = "browse"
        selectedIndex = 0

        if (view === "playlists" && Spotify.playlists.count === 0) Spotify.loadPlaylists()
        if (view === "queue") Spotify.loadQueue()
    }

    function cycleTab(direction) {
        const i = tabOrder.indexOf(currentView)
        switchTab(tabOrder[(i + direction + tabOrder.length) % tabOrder.length])
    }

    function openPlaylist(playlist) {
        if (!playlist) return
        Spotify.loadPlaylistTracks(playlist.id, playlist.name)
        playlistMode = "tracks"
        selectedIndex = 0
    }

    function backToPlaylists() {
        playlistMode = "browse"
        selectedIndex = 0
    }

    function playTrack(track) {
        if (!track) return
        Spotify.playNow(track)
        popup.close()
    }

    // ══ INPUT ════════════════════════════════════════════════════
    onOpened: {
        currentView = "nowPlaying"
        playlistMode = "browse"
        Spotify.clearSearch()
        Spotify.refreshDevice()
    }

    onSearchEdited: (text) => {
        if (currentView === "search") Spotify.search(text)
    }

    onAccepted: (index) => {
        if (!activeModel || index < 0 || index >= activeModel.count) return

        if (currentView === "playlists" && playlistMode === "browse") {
            openPlaylist(activeModel.get(index))
            return
        }
        if (currentView === "search" || inPlaylistTracks) {
            playTrack(activeModel.get(index))
            return
        }
    }

    onTabPressed: cycleTab(1)
    onBacktabPressed: cycleTab(-1)

    Binding {
        target: MprisState
        property: "positionPolling"
        value: popup.currentView === "nowPlaying" && popup.visible
    }

    // ══ UI ═══════════════════════════════════════════════════════
    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        // ── TAB BAR ──────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: popup.tabModel

                delegate: Rectangle {
                    required property var modelData
                    readonly property bool active: popup.currentView === modelData.key

                    Layout.preferredWidth: 90
                    Layout.preferredHeight: 28
                    radius: 8
                    color: active
                        ? Theme.hexToRgba(Theme.color5, 0.22)
                        : Theme.hexToRgba(Theme.foreground, 0.05)
                    border.color: active
                        ? Theme.hexToRgba(Theme.color5, 0.55)
                        : "transparent"
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        text: modelData.label
                        color: Theme.foreground
                        font.pixelSize: 12
                        font.bold: active
                    }

                    TapHandler {
                        onTapped: popup.switchTab(modelData.key)
                    }
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                visible: popup.inPlaylistTracks
                Layout.preferredWidth: 70
                Layout.preferredHeight: 28
                radius: 8
                color: Theme.hexToRgba(Theme.foreground, 0.05)

                Text {
                    anchors.centerIn: parent
                    text: "\uf060 Back"
                    font.family: "Symbols Nerd Font"
                    font.pixelSize: 11
                    color: Theme.foreground
                }

                TapHandler {
                    onTapped: popup.backToPlaylists()
                }
            }
        }

        // ── SEARCH ───────────────────────────────────────────────
        SelectableListView {
            id: searchList

            visible: popup.currentView === "search"
            Layout.fillWidth: true
            Layout.fillHeight: true

            model: Spotify.searchResults
            rowHeight: 56
            accentColor: Theme.color5

            emptyText: Spotify.isSearching
                ? "Searching..."
                : (Spotify.lastError !== ""
                    ? Spotify.lastError
                    : (popup.searchText === "" ? "Type to search" : "No results"))

            onSelectedIndexChanged: if (popup.selectedIndex !== selectedIndex) popup.selectedIndex = selectedIndex
            Connections {
                target: popup
                function onSelectedIndexChanged() {
                    if (searchList.selectedIndex !== popup.selectedIndex)
                        searchList.selectedIndex = popup.selectedIndex
                }
            }

            delegate: Component {
                TrackRow {
                    thumbnailSource: modelData ? (modelData.thumbnail ?? "") : ""
                    primaryText: modelData ? (modelData.title ?? "") : ""
                    secondaryText: modelData ? (modelData.artist ?? "") : ""
                    trailingText: modelData ? Spotify.formatDuration(modelData.durationMs ?? 0) : ""
                    onActivated: popup.playTrack(modelData)
                }
            }
        }

        // ── PLAYLISTS ────────────────────────────────────────────
        SelectableListView {
            id: playlistsList

            visible: popup.currentView === "playlists" && popup.playlistMode === "browse"
            Layout.fillWidth: true
            Layout.fillHeight: true

            model: Spotify.playlists
            rowHeight: 52
            accentColor: Theme.color5

            emptyText: Spotify.isLoadingPlaylists ? "Loading playlists..." : "No playlists found"

            onSelectedIndexChanged: if (popup.selectedIndex !== selectedIndex) popup.selectedIndex = selectedIndex
            Connections {
                target: popup
                function onSelectedIndexChanged() {
                    if (playlistsList.selectedIndex !== popup.selectedIndex)
                        playlistsList.selectedIndex = popup.selectedIndex
                }
            }

            delegate: Component {
                TrackRow {
                    thumbnailSize: 36
                    thumbnailSource: modelData ? (modelData.thumbnail ?? "") : ""
                    primaryText: modelData ? (modelData.name ?? "") : ""
                    secondaryText: modelData ? ((modelData.trackCount ?? 0) + " tracks") : ""
                    onActivated: popup.openPlaylist(modelData)
                }
            }
        }

        // ── PLAYLIST TRACKS ──────────────────────────────────────
        SelectableListView {
            id: playlistTracksList

            visible: popup.inPlaylistTracks
            Layout.fillWidth: true
            Layout.fillHeight: true

            model: Spotify.playlistTracks
            rowHeight: 56
            accentColor: Theme.color5

            emptyText: Spotify.isLoadingTracks ? "Loading tracks..." : "No tracks found"

            onSelectedIndexChanged: if (popup.selectedIndex !== selectedIndex) popup.selectedIndex = selectedIndex
            Connections {
                target: popup
                function onSelectedIndexChanged() {
                    if (playlistTracksList.selectedIndex !== popup.selectedIndex)
                        playlistTracksList.selectedIndex = popup.selectedIndex
                }
            }

            delegate: Component {
                TrackRow {
                    showThumbnail: false
                    primaryText: modelData ? (modelData.title ?? "") : ""
                    secondaryText: modelData ? (modelData.artist ?? "") : ""
                    trailingText: modelData ? Spotify.formatDuration(modelData.durationMs ?? 0) : ""
                    onActivated: popup.playTrack(modelData)
                }
            }
        }

        // ── QUEUE ────────────────────────────────────────────────
        SelectableListView {
            id: queueList

            visible: popup.currentView === "queue"
            Layout.fillWidth: true
            Layout.fillHeight: true

            model: Spotify.queueList
            rowHeight: 56
            headerHeight: 60
            accentColor: Theme.color5

            emptyText: Spotify.isLoadingQueue ? "Loading queue..." : "Queue is empty"

            onSelectedIndexChanged: if (popup.selectedIndex !== selectedIndex) popup.selectedIndex = selectedIndex
            Connections {
                target: popup
                function onSelectedIndexChanged() {
                    if (queueList.selectedIndex !== popup.selectedIndex)
                        queueList.selectedIndex = popup.selectedIndex
                }
            }

            header: Component {
                TrackRow {
                    overlineText: "\uf144 Now Playing"
                    thumbnailSource: (Spotify.currentTrack && Spotify.currentTrack.thumbnail)
                        ? Spotify.currentTrack.thumbnail
                        : ""
                    primaryText: Spotify.currentTrack ? Spotify.currentTrack.title : "Nothing playing"
                    secondaryText: Spotify.currentTrack ? Spotify.currentTrack.artist : ""
                }
            }

            delegate: Component {
                TrackRow {
                    showThumbnail: false
                    primaryText: modelData ? (modelData.title ?? "") : ""
                    secondaryText: modelData ? (modelData.artist ?? "") : ""
                    trailingText: modelData ? Spotify.formatDuration(modelData.durationMs ?? 0) : ""
                }
            }
        }

        // ── NOW PLAYING ──────────────────────────────────────────
        ColumnLayout {
            visible: popup.currentView === "nowPlaying"
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 8
            spacing: 16

            Item { Layout.fillHeight: true }

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 160
                Layout.preferredHeight: 160
                radius: 10
                color: Theme.hexToRgba(Theme.foreground, 0.05)
                clip: true

                Image {
                    anchors.fill: parent
                    source: MprisState.hasArt ? MprisState.trackArtUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: MprisState.hasArt
                }

                Text {
                    anchors.centerIn: parent
                    text: "󰎆"
                    color: Theme.hexToRgba(Theme.foreground, 0.4)
                    font.pixelSize: 44
                    font.family: "Symbols Nerd Font"
                    visible: !MprisState.hasArt
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: MprisState.hasPlayer
                        ? (MprisState.trackTitle || "Unknown Title")
                        : "Nothing playing"
                    color: Theme.foreground
                    font.pixelSize: 15
                    font.bold: true
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    visible: MprisState.hasPlayer
                    text: MprisState.trackArtist || "Unknown Artist"
                    color: Theme.hexToRgba(Theme.foreground, 0.6)
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }
            }

            TransportControls {
                Layout.alignment: Qt.AlignHCenter
                spacing: 24
                buttonSize: 42
            }

            SeekBar {
                Layout.fillWidth: true
            }

            Item { Layout.fillHeight: true }
        }
    }
}

