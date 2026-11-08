import Foundation
import SwiftUI

public struct FetchItem: Identifiable, Equatable {
    public let id: String
    public let key: String
    public let value: String
    public let iconName: String
    public let accentColor: Color
    public let percentage: Double? // 0.0 .. 1.0

    public var displayKey: String {
        if key.hasPrefix("Display (") { return "Display" }
        if key.hasPrefix("Battery (") { return "Battery" }
        if key.hasPrefix("Local IP (") { return "Local IP" }
        return key
    }

    public var displayValue: String {
        let lowerKey = key.lowercased()
        if lowerKey.contains("memory") || lowerKey.contains("swap") {
            var v = value
            if let range = v.range(of: #"\s*\(\d+(?:\.\d+)?%\)"#, options: .regularExpression) {
                v.removeSubrange(range)
            }
            return v.trimmingCharacters(in: .whitespaces)
        }
        if lowerKey.contains("disk") {
            var v = value
            if let range = v.range(of: #"\s*\(\d+(?:\.\d+)?%\)"#, options: .regularExpression) {
                v.removeSubrange(range)
            }
            return v.replacingOccurrences(of: " - ", with: " ")
                    .trimmingCharacters(in: .whitespaces)
        }
        if lowerKey.contains("battery") {
            var v = value
            if let range = v.range(of: #"^\d+(?:\.\d+)?%\s*"#, options: .regularExpression) {
                v.removeSubrange(range)
            }
            v = v.replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: "")
            return v.isEmpty ? value : v.trimmingCharacters(in: .whitespaces)
        }
        if lowerKey == "shell" && value == "xfetch" {
            if let sh = ProcessInfo.processInfo.environment["SHELL"] {
                return (sh as NSString).lastPathComponent
            }
        }
        if lowerKey == "terminal" && (value == "dumb" || value.isEmpty) {
            return "xfetch (Native UI)"
        }
        return value
    }

    public init(
        id: String? = nil,
        key: String,
        value: String,
        iconName: String? = nil,
        accentColor: Color? = nil,
        percentage: Double? = nil
    ) {
        self.id = id ?? UUID().uuidString
        self.key = key
        self.value = value
        self.percentage = percentage ?? Self.extractPercentage(from: value)
        self.iconName = iconName ?? Self.resolveIcon(for: key)
        self.accentColor = accentColor ?? Self.resolveColor(for: key)
    }

    public static func extractPercentage(from text: String) -> Double? {
        guard let match = text.range(of: #"(\d+(?:\.\d+)?)%"#, options: .regularExpression) else {
            return nil
        }
        let pctStr = text[match].dropLast()
        if let val = Double(pctStr) {
            return min(max(val / 100.0, 0.0), 1.0)
        }
        return nil
    }

    public static func resolveIcon(for key: String) -> String {
        let lower = key.lowercased()
        if lower == "os" || lower.hasPrefix("os ") || lower.hasPrefix("os:") { return "applelogo" }
        if lower.contains("host") { return "laptopcomputer" }
        if lower.contains("kernel") { return "gearshape.2" }
        if lower.contains("uptime") { return "clock" }
        if lower.contains("package") { return "shippingbox" }
        if lower.contains("shell") { return "chevron.left.forwardslash.chevron.right" }
        if lower.contains("display") { return "display" }
        if lower.contains("window manager") || lower.contains("wm") { return "macwindow.on.rectangle" }
        if lower.contains("theme") { return "paintbrush" }
        if lower.contains("font") { return "textformat" }
        if lower.contains("cursor") { return "cursorarrow.rays" }
        if lower.contains("terminal") { return "terminal" }
        if lower.contains("cpu") { return "cpu" }
        if lower.contains("gpu") { return "sparkles" }
        if lower.contains("memory") { return "memorychip" }
        if lower.contains("swap") { return "arrow.triangle.2.circlepath" }
        if lower.contains("disk") { return "internaldrive" }
        if lower.contains("ip") || lower.contains("network") { return "network" }
        if lower.contains("battery") { return "battery.100.bolt" }
        if lower.contains("power") { return "bolt.fill" }
        if lower.contains("locale") { return "globe" }
        return "info.circle"
    }

    public static func resolveColor(for key: String) -> Color {
        let lower = key.lowercased()
        if lower.contains("os") { return Color.blue }
        if lower.contains("host") { return Color.indigo }
        if lower.contains("kernel") { return Color.orange }
        if lower.contains("uptime") { return Color.yellow }
        if lower.contains("package") { return Color.teal }
        if lower.contains("shell") { return Color.cyan }
        if lower.contains("display") { return Color.purple }
        if lower.contains("window manager") || lower.contains("wm") { return Color.pink }
        if lower.contains("theme") { return Color.pink }
        if lower.contains("font") { return Color.mint }
        if lower.contains("cursor") { return Color.gray }
        if lower.contains("terminal") { return Color.green }
        if lower.contains("cpu") { return Color.orange }
        if lower.contains("gpu") { return Color.red }
        if lower.contains("memory") { return Color.blue }
        if lower.contains("swap") { return Color.purple }
        if lower.contains("disk") { return Color.mint }
        if lower.contains("ip") || lower.contains("network") { return Color.teal }
        if lower.contains("battery") { return Color.green }
        if lower.contains("power") { return Color.yellow }
        if lower.contains("locale") { return Color.indigo }
        return Color.blue
    }
}

public struct FetchData: Equatable {
    public let user: String
    public let host: String
    public let items: [FetchItem]
    public let rawOutput: String
    public let timestamp: Date

    public init(
        user: String,
        host: String,
        items: [FetchItem],
        rawOutput: String,
        timestamp: Date = Date()
    ) {
        self.user = user
        self.host = host
        self.items = items
        self.rawOutput = rawOutput
        self.timestamp = timestamp
    }

    public var title: String {
        return "\(user)@\(host)"
    }

    public func item(for prefix: String) -> FetchItem? {
        let lower = prefix.lowercased()
        return items.first { $0.key.lowercased().starts(with: lower) }
    }

    public static func getLocalHostName() -> String {
        var size = 0
        sysctlbyname("kern.hostname", nil, &size, nil, 0)
        guard size > 0 else { return "localhost" }
        var buffer = [CChar](repeating: 0, count: size + 1)
        sysctlbyname("kern.hostname", &buffer, &size, nil, 0)
        let name = String(cString: buffer).trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "localhost" : name
    }

    public static func parse(pipeOutput: String) -> FetchData {
        let lines = pipeOutput.components(separatedBy: .newlines)
        var user = NSUserName()
        var host = getLocalHostName()
        var items: [FetchItem] = []

        var i = 0
        while i < lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespaces)
            i += 1
            if line.isEmpty { continue }

            // Check if line is user@host
            if line.contains("@") && !line.contains(":") {
                let parts = line.split(separator: "@", maxSplits: 1).map(String.init)
                if parts.count == 2 {
                    user = parts[0]
                    host = parts[1]
                }
                continue
            }

            // Skip divider like "---------------"
            if line.allSatisfy({ $0 == "-" || $0 == "—" }) {
                continue
            }

            // Parse "Key: Value"
            if let colonIdx = line.firstIndex(of: ":") {
                let key = String(line[..<colonIdx]).trimmingCharacters(in: .whitespaces)
                let val = String(line[line.index(after: colonIdx)...]).trimmingCharacters(in: .whitespaces)
                if !key.isEmpty && !val.isEmpty {
                    items.append(FetchItem(key: key, value: val))
                }
            }
        }

        return FetchData(user: user, host: host, items: items, rawOutput: pipeOutput)
    }
}
