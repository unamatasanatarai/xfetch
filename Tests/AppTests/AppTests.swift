import Foundation
import SwiftUI

public enum AppTests {
    public static func run(testRunner: (String, () throws -> Void) -> Void) {
        testRunner("AppConfig returns valid non-empty application name") {
            assert(!AppConfig.appName.isEmpty, "App name should not be empty")
        }

        testRunner("AppConfig returns valid bundle identifier") {
            assert(!AppConfig.bundleIdentifier.isEmpty, "Bundle identifier should not be empty")
            assert(AppConfig.bundleIdentifier.contains("."), "Bundle identifier should be reverse-DNS style")
        }

        testRunner("AppConfig provides version string") {
            assert(!AppConfig.version.isEmpty, "Version should not be empty")
        }

        testRunner("AppConfig provides build number") {
            assert(!AppConfig.buildNumber.isEmpty, "Build number should not be empty")
        }

        testRunner("FetchItem percentage extractor extracts percentage correctly") {
            let pct1 = FetchItem.extractPercentage(from: "9.48 GiB / 16.00 GiB (59%)")
            assert(pct1 != nil, "Percentage should be extracted")
            assert(abs(pct1! - 0.59) < 0.001, "Percentage should be 0.59")

            let pct2 = FetchItem.extractPercentage(from: "15% [AC Connected, Charging]")
            assert(pct2 != nil, "Battery percentage should be extracted")
            assert(abs(pct2! - 0.15) < 0.001, "Battery percentage should be 0.15")

            let pct3 = FetchItem.extractPercentage(from: "No percentage here")
            assert(pct3 == nil, "No percentage should be extracted")
        }

        testRunner("FetchItem generates unique IDs for identical keys") {
            let item1 = FetchItem(key: "GPU", value: "Apple M3 Max")
            let item2 = FetchItem(key: "GPU", value: "External eGPU")
            assert(item1.id != item2.id, "FetchItem IDs must be unique even with identical keys to avoid SwiftUI ForEach collisions")
        }

        testRunner("FetchItem resolves appropriate SF Symbol icons and colors") {
            assert(FetchItem.resolveIcon(for: "OS") == "applelogo", "OS icon should be applelogo")
            assert(FetchItem.resolveIcon(for: "CPU") == "cpu", "CPU icon should be cpu")
            assert(FetchItem.resolveIcon(for: "GPU") == "sparkles", "GPU icon should be sparkles")
            assert(FetchItem.resolveIcon(for: "Memory") == "memorychip", "Memory icon should be memorychip")
            assert(FetchItem.resolveIcon(for: "Battery") == "battery.100.bolt", "Battery icon should be battery.100.bolt")
            assert(FetchItem.resolveIcon(for: "Disk (/)") == "internaldrive", "Disk icon should be internaldrive")
        }

        testRunner("FetchData parses text summary accurately") {
            let sample = """
            user@host
            ----------------
            OS: macOS Monterey 12.7.6 (21H1320) x86_64
            Host: MacBookPro12,1
            Kernel: Darwin 21.6.0
            Memory: 8.00 GiB / 16.00 GiB (50%)
            """
            let parsed = FetchData.parse(pipeOutput: sample)
            assert(parsed.user == "user", "User should be 'user', got '\(parsed.user)'")
            assert(parsed.host == "host", "Host should be 'host', got '\(parsed.host)'")
            assert(parsed.items.count == 4, "Should have 4 items, got \(parsed.items.count)")
            assert(parsed.item(for: "Memory")?.percentage == 0.5, "Memory percentage should be 0.5")
            assert(parsed.item(for: "OS")?.value.contains("macOS") == true, "OS value should contain macOS")
        }

        testRunner("SystemProbe generates comprehensive native macOS telemetry") {
            let probeData = SystemProbe.probe()
            assert(!probeData.user.isEmpty, "Probe user should not be empty")
            assert(!probeData.host.isEmpty, "Probe host should not be empty")
            assert(probeData.items.count >= 8, "Probe should have rich hardware/system items (got \(probeData.items.count))")

            assert(probeData.item(for: "OS") != nil, "Probe must have OS item")
            assert(probeData.item(for: "CPU") != nil, "Probe must have CPU item")
            assert(probeData.item(for: "Memory") != nil, "Probe must have Memory item")
            assert(probeData.item(for: "Kernel") != nil, "Probe must have Kernel item")
            assert(probeData.item(for: "Uptime") != nil, "Probe must have Uptime item")
            assert(probeData.item(for: "Disk") != nil, "Probe must have Disk item")
            assert(probeData.item(for: "Terminal") != nil, "Probe must have Terminal item")

            // Verify memory metrics have valid percentage
            let memItem = probeData.item(for: "Memory")!
            assert(memItem.percentage != nil && memItem.percentage! > 0.0, "Memory must include a valid gauge percentage")

            print("  [Info] Native probe collected \(probeData.items.count) system items for \(probeData.user)@\(probeData.host)")
        }

        testRunner("FetchService performs asynchronous native refresh") {
            let service = FetchService()
            service.refresh()

            let deadline = Date(timeIntervalSinceNow: 2.0)
            while service.data == nil && Date() < deadline {
                RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.02))
            }

            assert(service.data != nil, "FetchService data must be populated")
            assert(!service.isLoading, "Service should not be loading after completion")
        }
    }
}
