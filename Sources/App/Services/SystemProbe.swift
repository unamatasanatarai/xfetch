import Foundation
import Darwin
import IOKit.ps
import Metal
import AppKit

public enum SystemProbe {
    public static func probe() -> FetchData {
        let user = NSUserName()
        let host = FetchData.getLocalHostName()
        var items: [FetchItem] = []

        // 1. OS
        let os = ProcessInfo.processInfo.operatingSystemVersion
        let build = sysctlString("kern.osversion") ?? ""
        let arch = sysctlString("hw.machine") ?? ""
        let marketingNames: [Int: String] = [
            15: "Sequoia",
            14: "Sonoma",
            13: "Ventura",
            12: "Monterey",
            11: "Big Sur"
        ]
        let mName = marketingNames[os.majorVersion] ?? ""
        let verStr = "\(os.majorVersion).\(os.minorVersion).\(os.patchVersion)"
        let buildPart = build.isEmpty ? "" : " (\(build))"
        let archPart = arch.isEmpty ? "" : " \(arch)"
        let osDisplay = mName.isEmpty ? "macOS \(verStr)\(buildPart)\(archPart)" : "macOS \(mName) \(verStr)\(buildPart)\(archPart)"
        items.append(FetchItem(key: "OS", value: osDisplay))

        // 2. Host
        if let model = sysctlString("hw.model") {
            items.append(FetchItem(key: "Host", value: model))
        }

        // 3. Kernel
        if let release = sysctlString("kern.osrelease") {
            items.append(FetchItem(key: "Kernel", value: "Darwin \(release)"))
        }

        // 4. Uptime
        let uptimeSec = ProcessInfo.processInfo.systemUptime
        let hours = Int(uptimeSec) / 3600
        let mins = (Int(uptimeSec) % 3600) / 60
        let days = hours / 24
        let remHours = hours % 24
        let uptimeStr = days > 0 ? "\(days) days, \(remHours) hours, \(mins) mins" : "\(hours) hours, \(mins) mins"
        items.append(FetchItem(key: "Uptime", value: uptimeStr))

        // 5. Packages (Homebrew, MacPorts, Nix)
        if let pkgs = getPackageCounts() {
            items.append(FetchItem(key: "Packages", value: pkgs))
        }

        // 6. Shell
        if let shellPath = ProcessInfo.processInfo.environment["SHELL"] {
            let shellName = (shellPath as NSString).lastPathComponent
            items.append(FetchItem(key: "Shell", value: shellName))
        }

        // 7. Displays
        for (idx, screen) in NSScreen.screens.enumerated() {
            let scale = screen.backingScaleFactor
            let pxW = Int(screen.frame.width * scale)
            let pxH = Int(screen.frame.height * scale)
            let hz = CGDisplayCopyDisplayMode(CGMainDisplayID())?.refreshRate ?? 0
            let hzStr = hz > 0 ? " @ \(Int(hz))Hz" : ""
            let key = NSScreen.screens.count > 1 ? "Display (\(idx + 1))" : "Display"
            items.append(FetchItem(key: key, value: "\(pxW)x\(pxH)\(hzStr)"))
        }

        // 8. WM
        items.append(FetchItem(key: "WM", value: "Quartz Compositor"))

        // 9. Terminal / UI
        items.append(FetchItem(key: "Terminal", value: "xfetch (Native UI)"))

        // 10. CPU
        let cpuBrand = sysctlString("machdep.cpu.brand_string")
        let coreCount = ProcessInfo.processInfo.activeProcessorCount
        let cpuName = cpuBrand ?? (arch == "arm64" ? "Apple Silicon" : "Intel Core")

        var pCores: Int32 = 0
        var pSize = MemoryLayout<Int32>.size
        let hasP = sysctlbyname("hw.perflevel0.logicalcpu", &pCores, &pSize, nil, 0) == 0

        var eCores: Int32 = 0
        var eSize = MemoryLayout<Int32>.size
        let hasE = sysctlbyname("hw.perflevel1.logicalcpu", &eCores, &eSize, nil, 0) == 0

        let coreDesc: String
        if hasP && hasE && eCores > 0 {
            coreDesc = "\(coreCount) Cores: \(pCores)P + \(eCores)E"
        } else {
            coreDesc = "\(coreCount)"
        }
        items.append(FetchItem(key: "CPU", value: "\(cpuName) (\(coreDesc))"))

        // 11. GPU (via Metal API)
        let gpus = MTLCopyAllDevices()
        if !gpus.isEmpty {
            for (idx, gpu) in gpus.enumerated() {
                let key = gpus.count > 1 ? "GPU (\(idx + 1))" : "GPU"
                items.append(FetchItem(key: key, value: gpu.name))
            }
        }

        // 12. Memory (Physical & Mach VM Statistics)
        let totalMem = ProcessInfo.processInfo.physicalMemory
        let usedMem = getUsedMemoryBytes()
        let totalGiB = Double(totalMem) / 1_073_741_824.0
        let usedGiB = Double(usedMem) / 1_073_741_824.0
        let memPct = totalMem > 0 ? (Double(usedMem) / Double(totalMem)) * 100.0 : 0
        let memStr = String(format: "%.2f GiB / %.2f GiB (%.0f%%)", usedGiB, totalGiB, memPct)
        items.append(FetchItem(key: "Memory", value: memStr, percentage: memPct / 100.0))

        // 13. Swap Memory
        if let swap = getSwapMemoryInfo(), swap.total > 0 {
            let usedGiB = Double(swap.used) / 1_073_741_824.0
            let totalGiB = Double(swap.total) / 1_073_741_824.0
            let swapPct = (Double(swap.used) / Double(swap.total)) * 100.0
            let swapStr = String(format: "%.2f GiB / %.2f GiB (%.0f%%)", usedGiB, totalGiB, swapPct)
            items.append(FetchItem(key: "Swap", value: swapStr, percentage: swapPct / 100.0))
        }

        // 14. Disk (Root Mount)
        if let diskInfo = getRootDiskInfo() {
            let diskPct = (Double(diskInfo.used) / Double(diskInfo.total)) * 100.0
            let usedGiB = Double(diskInfo.used) / 1_073_741_824.0
            let totalGiB = Double(diskInfo.total) / 1_073_741_824.0
            let diskStr = String(format: "%.2f GiB / %.2f GiB (%.0f%%)", usedGiB, totalGiB, diskPct)
            items.append(FetchItem(key: "Disk (/)", value: diskStr, percentage: diskPct / 100.0))
        }

        // 15. Battery
        if let battery = getBatteryInfo() {
            items.append(FetchItem(key: "Battery", value: battery.desc, percentage: Double(battery.pct) / 100.0))
        }

        // 16. Local IP
        if let localIP = getPrimaryLocalIP() {
            items.append(FetchItem(key: "Local IP", value: localIP))
        }

        // 17. Locale
        items.append(FetchItem(key: "Locale", value: Locale.current.identifier))

        // Build raw text output for clipboard copying
        var raw = "\(user)@\(host)\n----------------\n"
        for item in items {
            raw += "\(item.key): \(item.value)\n"
        }

        return FetchData(user: user, host: host, items: items, rawOutput: raw)
    }

    private static func sysctlString(_ name: String) -> String? {
        var size = 0
        sysctlbyname(name, nil, &size, nil, 0)
        guard size > 0 else { return nil }
        var buffer = [CChar](repeating: 0, count: size + 1)
        sysctlbyname(name, &buffer, &size, nil, 0)
        let str = String(cString: buffer).trimmingCharacters(in: .whitespacesAndNewlines)
        return str.isEmpty ? nil : str
    }

    private static func getPackageCounts() -> String? {
        var parts: [String] = []

        // Homebrew
        let brewCellars = ["/opt/homebrew/Cellar", "/usr/local/Cellar"]
        for c in brewCellars {
            if let contents = try? FileManager.default.contentsOfDirectory(atPath: c) {
                let count = contents.filter { !$0.hasPrefix(".") }.count
                if count > 0 {
                    parts.append("\(count) (brew)")
                    break
                }
            }
        }

        // MacPorts
        if let macports = try? FileManager.default.contentsOfDirectory(atPath: "/opt/local/var/macports/software") {
            let count = macports.filter { !$0.hasPrefix(".") }.count
            if count > 0 {
                parts.append("\(count) (macports)")
            }
        }

        // Nix
        let nixManifest = (NSHomeDirectory() as NSString).appendingPathComponent(".nix-profile/manifest.json")
        if FileManager.default.fileExists(atPath: nixManifest) {
            parts.append("nix")
        }

        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }

    private static func getUsedMemoryBytes() -> UInt64 {
        var vmStats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        let hostPort = mach_host_self()
        defer {
            mach_port_deallocate(mach_task_self_, hostPort)
        }

        let result = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(hostPort, HOST_VM_INFO64, $0, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            return ProcessInfo.processInfo.physicalMemory / 2
        }

        let pageSize = UInt64(vm_kernel_page_size)
        let active = UInt64(vmStats.active_count) * pageSize
        let wired = UInt64(vmStats.wire_count) * pageSize
        let compressed = UInt64(vmStats.compressor_page_count) * pageSize
        return active + wired + compressed
    }

    private static func getSwapMemoryInfo() -> (used: UInt64, total: UInt64)? {
        var swap = xsw_usage()
        var size = MemoryLayout<xsw_usage>.size
        guard sysctlbyname("vm.swapusage", &swap, &size, nil, 0) == 0 else { return nil }
        return (used: swap.xsu_used, total: swap.xsu_total)
    }

    private static func getRootDiskInfo() -> (used: UInt64, total: UInt64)? {
        var stat = statfs()
        guard statfs("/", &stat) == 0 else { return nil }
        let total = UInt64(stat.f_blocks) * UInt64(stat.f_bsize)
        let free = UInt64(stat.f_bavail) * UInt64(stat.f_bsize)
        let used = total > free ? total - free : 0
        return (used: used, total: total)
    }

    private static func getBatteryInfo() -> (pct: Int, desc: String)? {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
              let firstSource = sources.first,
              let desc = IOPSGetPowerSourceDescription(snapshot, firstSource)?.takeUnretainedValue() as? [String: Any] else {
            return nil
        }

        let current = desc[kIOPSCurrentCapacityKey as String] as? Int ?? 0
        let maxCap = desc[kIOPSMaxCapacityKey as String] as? Int ?? 100
        let isCharging = desc[kIOPSIsChargingKey as String] as? Bool ?? false
        let pct = maxCap > 0 ? (current * 100) / maxCap : current
        let state = isCharging ? "Charging" : "Discharging"
        return (pct: pct, desc: "\(pct)% [\(state)]")
    }

    private static func getPrimaryLocalIP() -> String? {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return nil }
        defer { freeifaddrs(ifaddr) }

        var ptr: UnsafeMutablePointer<ifaddrs>? = firstAddr
        while let cur = ptr {
            let flags = Int32(cur.pointee.ifa_flags)
            let isUp = (flags & IFF_UP) != 0
            let isLoopback = (flags & IFF_LOOPBACK) != 0
            if isUp && !isLoopback, let sa = cur.pointee.ifa_addr, sa.pointee.sa_family == UInt8(AF_INET) {
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                if getnameinfo(sa, socklen_t(sa.pointee.sa_len), &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 {
                    let ip = String(cString: hostname)
                    let ifName = String(cString: cur.pointee.ifa_name)
                    return "\(ip) (\(ifName))"
                }
            }
            ptr = cur.pointee.ifa_next
        }
        return nil
    }
}
