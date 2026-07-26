pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property real cpuUsage: 0
    property real memUsage: 0

    property var perCore: []
    property real memUsedKb: 0
    property real memTotalKb: 0

    property bool gpuPollActive: false
    property real gpuUtil: 0
    property real gpuMemUsedMb: 0
    property real gpuMemTotalMb: 0
    property real gpuTempC: 0
    property real gpuPowerW: 0

    FileView {
        id: settingsFile
        path: Quickshell.dataPath("sysmonitor-settings.json")
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        JsonAdapter {
            id: settings
            property bool fetchNvidia: true
        }
    }
    readonly property alias fetchNvidiaEnabled: settings.fetchNvidia
    function setFetchNvidia(enabled) { settings.fetchNvidia = enabled }

    // ---- CPU temp / fan speeds (lm-sensors) ----
    property bool sensorPollActive: false
    property real cpuTempC: 0
    property var fans: []

    // ---- disk usage ----
    property bool diskPollActive: false
    property var disks: []

    // ---- network throughput ----
    property real netRxKBs: 0
    property real netTxKBs: 0
    property var _prevNet: null

    // ---- process list ----
    property bool processPollActive: false
    property var processes: []

    property var _prevCpu: []

    Timer {
        interval: 1500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root._sampleCpu(statFile.text())
            root._sampleMem(meminfoFile.text())
            root._sampleNet(netDevFile.text())
            statFile.reload()
            meminfoFile.reload()
            netDevFile.reload()

            if (root.gpuPollActive && root.fetchNvidiaEnabled) gpuProc.running = true
            if (root.sensorPollActive) sensorsProc.running = true
        }
    }

    FileView {
        id: netDevFile
        path: "/proc/net/dev"
    }

    Timer {
        id: diskTimer
        interval: 5000
        running: root.diskPollActive
        repeat: true
        triggeredOnStart: true
        onTriggered: diskProc.running = true
    }

    Timer {
        id: processTimer
        interval: 2000
        running: root.processPollActive
        repeat: true
        triggeredOnStart: true
        onTriggered: processProc.running = true
    }

    FileView {
        id: statFile
        path: "/proc/stat"
    }

    FileView {
        id: meminfoFile
        path: "/proc/meminfo"
    }

    function _sampleCpu(text) {
        if (!text) return

        const lines = text.split("\n")
        const samples = []

        for (let i = 0; i < lines.length; i++) {
            const line = lines[i]
            if (!line.startsWith("cpu")) break

            const parts = line.trim().split(/\s+/)
            const v = parts.slice(1).map(Number)
            if (v.length < 8) continue

            const idle = v[3] + v[4]
            let total = 0
            for (let f = 0; f < 8; f++) total += v[f]

            samples.push({ total: total, idle: idle })
        }

        if (samples.length === 0) return

        if (root._prevCpu.length !== samples.length) {
            root._prevCpu = samples
            return
        }

        const cores = []
        for (let c = 1; c < samples.length; c++) {
            cores.push({ usage: root._usageDelta(root._prevCpu[c], samples[c]) })
        }

        root.cpuUsage = root._usageDelta(root._prevCpu[0], samples[0])
        root.perCore = cores
        root._prevCpu = samples
    }

    function _usageDelta(prev, now) {
        const dTotal = now.total - prev.total
        const dIdle = now.idle - prev.idle
        return dTotal > 0 ? Math.max(0, Math.min(1, 1 - dIdle / dTotal)) : 0
    }

    function _sampleMem(text) {
        if (!text) return

        let total = 0
        let avail = 0
        const lines = text.split("\n")
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i]
            if (line.startsWith("MemTotal:")) {
                total = Number(line.replace(/[^0-9]/g, ""))
            } else if (line.startsWith("MemAvailable:")) {
                avail = Number(line.replace(/[^0-9]/g, ""))
            }
            if (total > 0 && avail > 0) break
        }

        if (total <= 0) return
        root.memTotalKb = total
        root.memUsedKb = total - avail
        root.memUsage = Math.max(0, Math.min(1, (total - avail) / total))
    }

    function _sampleNet(text) {
        if (!text) return

        const lines = text.split("\n").slice(2)
        let rxTotal = 0
        let txTotal = 0

        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim()
            if (!line) continue
            const colon = line.indexOf(":")
            if (colon < 0) continue
            const iface = line.slice(0, colon).trim()
            if (iface === "lo") continue

            const fields = line.slice(colon + 1).trim().split(/\s+/).map(Number)
            if (fields.length < 16) continue
            rxTotal += fields[0]
            txTotal += fields[8]
        }

        const now = { rx: rxTotal, tx: txTotal, time: Date.now() }
        if (root._prevNet) {
            const dt = (now.time - root._prevNet.time) / 1000
            if (dt > 0) {
                root.netRxKBs = Math.max(0, (now.rx - root._prevNet.rx) / dt / 1024)
                root.netTxKBs = Math.max(0, (now.tx - root._prevNet.tx) / dt / 1024)
            }
        }
        root._prevNet = now
    }

    function startSensorPolling() { sensorPollActive = true }
    function stopSensorPolling() { sensorPollActive = false }

    function startDiskPolling() { diskPollActive = true }
    function stopDiskPolling() { diskPollActive = false }

    function startProcessPolling() { processPollActive = true }
    function stopProcessPolling() { processPollActive = false }

    function killProcess(pid) {
        killProc.command = ["kill", String(pid)]
        killProc.running = true
        refreshAfterKillTimer.restart()
    }

    Timer {
        id: refreshAfterKillTimer
        interval: 300
        onTriggered: if (root.processPollActive) processProc.running = true
    }

    Process {
        id: killProc
        command: []
    }

    Process {
        id: gpuProc
        command: [
            "nvidia-smi",
            "--query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu,power.draw",
            "--format=csv,noheader,nounits"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const line = (this.text || "").trim().split("\n")[0]
                if (!line) return
                const f = line.split(",").map(s => Number(s.trim()))
                if (f.length < 5) return
                root.gpuUtil = (f[0] || 0) / 100
                root.gpuMemUsedMb = f[1] || 0
                root.gpuMemTotalMb = f[2] || 0
                root.gpuTempC = f[3] || 0
                root.gpuPowerW = f[4] || 0
            }
        }
    }

    function startGpuPolling() { gpuPollActive = true }
    function stopGpuPolling() { gpuPollActive = false }

    // ---- CPU temp / fan (lm-sensors, JSON output) ----
    Process {
        id: sensorsProc
        command: ["sensors", "-j"]
        stdout: StdioCollector {
            onStreamFinished: root._sampleSensors(this.text)
        }
    }

    function _sampleSensors(jsonText) {
        if (!jsonText) return
        let data
        try {
            data = JSON.parse(jsonText)
        } catch (e) {
            return
        }

        let temp = null
        const fanList = []

        for (const chipName in data) {
            const chip = data[chipName]
            for (const featureName in chip) {
                const feature = chip[featureName]
                if (typeof feature !== "object" || feature === null) continue
                const lname = featureName.toLowerCase()

                if (temp === null && (lname.includes("tctl") || lname.includes("tdie") || lname.includes("package"))) {
                    for (const key in feature) {
                        if (key.includes("_input")) { temp = feature[key]; break }
                    }
                }

                if (lname.startsWith("fan")) {
                    for (const key in feature) {
                        if (key.includes("_input")) {
                            fanList.push({ name: featureName, rpm: feature[key] })
                            break
                        }
                    }
                }
            }
        }

        if (temp !== null) root.cpuTempC = temp
        root.fans = fanList
    }

    // ---- disk usage (per real mount point) ----
    Process {
        id: diskProc
        command: ["bash", "-c",
            "df -B1 --output=target,size,used | tail -n +2"]
        stdout: StdioCollector {
            onStreamFinished: root._sampleDisks(this.text)
        }
    }

    function _sampleDisks(text) {
        if (!text) return
        const skipPrefixes = ["/dev", "/proc", "/sys", "/run", "/boot/efi"]
        const list = []

        for (const rawLine of text.trim().split("\n")) {
            const parts = rawLine.trim().split(/\s+/)
            if (parts.length < 3) continue
            const target = parts[0]
            const size = Number(parts[1])
            const used = Number(parts[2])
            if (!size || skipPrefixes.some(p => target.startsWith(p))) continue

            list.push({
                mount: target,
                sizeBytes: size,
                usedBytes: used,
                usage: size > 0 ? used / size : 0
            })
        }

        root.disks = list
    }

    // ---- process list (top by CPU, capped for sanity) ----
    Process {
        id: processProc
        command: ["bash", "-c",
            "ps -eo pid,comm,%cpu,%mem --sort=-%cpu --no-headers | head -n 60"]
        stdout: StdioCollector {
            onStreamFinished: root._sampleProcesses(this.text)
        }
    }

    function _sampleProcesses(text) {
        if (!text) return
        const list = []

        for (const rawLine of text.trim().split("\n")) {
            const line = rawLine.trim()
            if (!line) continue
            const parts = line.split(/\s+/)
            if (parts.length < 4) continue
            const pid = Number(parts[0])
            const cpu = Number(parts[parts.length - 2])
            const mem = Number(parts[parts.length - 1])
            const comm = parts.slice(1, parts.length - 2).join(" ")
            if (!pid) continue

            list.push({ pid: pid, name: comm, cpu: cpu, mem: mem })
        }

        root.processes = list
    }
}
