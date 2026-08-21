pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string backendScript: Quickshell.env("HOME") + "/.config/quickshell/scripts/spotify-backend.py"

    // ── SEARCH STATE ───────────────────────────────────────────
    property ListModel searchResults: ListModel {}
    property bool isSearching: false
    property string lastError: ""

    property int debounceMs: 350
    property string _pendingQuery: ""

    Timer {
        id: debounceTimer
        interval: root.debounceMs
        onTriggered: root._runSearch(root._pendingQuery)
    }

    function search(query) {
        _pendingQuery = query ?? ""
        if (_pendingQuery.trim() === "") {
            debounceTimer.stop()
            searchResults.clear()
            isSearching = false
            return
        }
        debounceTimer.restart()
    }

    function _runSearch(query) {
        if (searchProcess.running) searchProcess.running = false
        isSearching = true
        lastError = ""
        searchProcess.command = ["python3", root.backendScript, "search", query]
        searchProcess.running = true
    }

    Process {
        id: searchProcess
        stdout: StdioCollector {
            onStreamFinished: {
                root.isSearching = false
                try {
                    const data = JSON.parse(text)
                    if (!data.ok) {
                        root.lastError = data.error ?? "Search failed"
                        return
                    }
                    root.searchResults.clear()
                    for (const t of data.results) {
                        root.searchResults.append({
                            uri: t.uri,
                            title: t.title,
                            artist: t.artist,
                            durationMs: t.durationMs,
                            thumbnail: t.thumbnail ?? ""
                        })
                    }
                } catch (err) {
                    root.lastError = "Couldn't parse search results"
                    console.warn("[Spotify] parse failed:", err)
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "") console.warn("[Spotify] stderr:", text)
            }
        }
    }

    // ── PLAYLISTS ──────────────────────────────────────────────
    property ListModel playlists: ListModel {}
    property ListModel playlistTracks: ListModel {}
    property bool isLoadingPlaylists: false
    property bool isLoadingTracks: false
    property string currentPlaylistName: ""

    function loadPlaylists() {
        isLoadingPlaylists = true
        playlistsProcess.command = ["python3", root.backendScript, "playlists"]
        playlistsProcess.running = true
    }

    Process {
        id: playlistsProcess
        stdout: StdioCollector {
            onStreamFinished: {
                root.isLoadingPlaylists = false
                try {
                    const data = JSON.parse(text)
                    if (!data.ok) { root.lastError = data.error ?? ""; return }
                    root.playlists.clear()
                    for (const p of data.playlists) root.playlists.append(p)
                } catch (err) {
                    console.warn("[Spotify] playlists parse failed:", err)
                }
            }
        }
    }

    function loadPlaylistTracks(playlistId, name) {
        root.currentPlaylistName = name ?? ""
        root.playlistTracks.clear()
        isLoadingTracks = true
        tracksProcess.command = ["python3", root.backendScript, "playlist", playlistId]
        tracksProcess.running = true
    }

    Process {
        id: tracksProcess
        stdout: StdioCollector {
            onStreamFinished: {
                root.isLoadingTracks = false
                try {
                    const data = JSON.parse(text)
                    if (!data.ok) { root.lastError = data.error ?? ""; return }
                    root.playlistTracks.clear()
                    for (const t of data.tracks) root.playlistTracks.append(t)
                } catch (err) {
                    console.warn("[Spotify] tracks parse failed:", err)
                }
            }
        }
    }

    // ── DEVICE ─────────────────────────────────────────────────
    property string deviceId: ""
    property string deviceName: ""
    readonly property bool hasDevice: deviceId !== ""

    function refreshDevice() {
        devicesProcess.command = ["python3", root.backendScript, "devices"]
        devicesProcess.running = true
    }

    Process {
        id: devicesProcess
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text)
                    if (!data.ok) return
                    const own = data.devices.find(d => d.name === "quickshell-player")
                    const active = data.devices.find(d => d.is_active)
                    const picked = own ?? active ?? data.devices[0] ?? null
                    if (picked) {
                        root.deviceId = picked.id
                        root.deviceName = picked.name
                        if (!picked.is_active) root.activateDevice(picked.id)
                    }
                } catch (err) {
                    console.warn("[Spotify] devices parse failed:", err)
                }
            }
        }
    }

    function activateDevice(id) {
        activateProcess.command = ["python3", root.backendScript, "activate", id]
        activateProcess.running = true
    }

    Process {
        id: activateProcess
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text)
                    if (!data.ok) console.warn("[Spotify] activate failed:", data.error)
                } catch (err) {
                    console.warn("[Spotify] activate parse failed:", err)
                }
            }
        }
    }

    Component.onCompleted: root.refreshDevice()

    // ── QUEUE ────────────────────────────────────────────────
    property var currentTrack: null
    property ListModel queueList: ListModel {}
    property bool isLoadingQueue: false

    function loadQueue() {
        isLoadingQueue = true
        queueStateProcess.command = ["python3", root.backendScript, "queue_state"]
        queueStateProcess.running = true
    }

    Process {
        id: queueStateProcess
        stdout: StdioCollector {
            onStreamFinished: {
                root.isLoadingQueue = false
                try {
                    const data = JSON.parse(text)
                    if (!data.ok) { root.lastError = data.error ?? ""; return }
                    root.currentTrack = data.current ?? null
                    root.queueList.clear()
                    for (const t of (data.upcoming ?? [])) root.queueList.append(t)
                } catch (err) {
                    console.warn("[Spotify] queue_state parse failed:", err)
                }
            }
        }
    }

    // ── PLAYBACK ───────────────────────────────────────────────
    function playNow(item) {
        if (!root.hasDevice) {
            root.refreshDevice()
            root.lastError = "No Spotify device found"
            return
        }
        queueProcess.command = [
            "python3", root.backendScript, "queue", item.uri, root.deviceId
        ]
        queueProcess.running = true
    }

    Process {
        id: queueProcess
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text)
                    if (!data.ok) {
                        root.lastError = data.error ?? "Queue failed"
                        console.warn("[Spotify] queue failed:", data.error)
                    }
                } catch (err) {
                    console.warn("[Spotify] queue parse failed:", err)
                }
            }
        }
    }

    function formatDuration(ms) {
        const seconds = Math.floor((ms ?? 0) / 1000)
        const m = Math.floor(seconds / 60)
        const s = seconds % 60
        return m + ":" + (s < 10 ? "0" + s : s)
    }

    function clearSearch() {
        debounceTimer.stop()
        searchResults.clear()
        isSearching = false
        lastError = ""
    }
}
