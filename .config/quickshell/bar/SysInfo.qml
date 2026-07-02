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

    property var _prevCpu: []

    Timer {
        interval: 1500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root._sampleCpu(statFile.text())
            root._sampleMem(meminfoFile.text())
            statFile.reload()
            meminfoFile.reload()

            if (root.gpuPollActive) gpuProc.running = true
        }
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
}
