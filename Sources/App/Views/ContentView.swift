import SwiftUI
import AppKit

public struct ContentView: View {
    @StateObject private var service = FetchService.shared
    @State private var logoTheme: LogoTheme = .retroRainbow
    @State private var copied: Bool = false
    @State private var isSpinning: Bool = false

    public init() {}

    public var body: some View {
        ZStack {
            VisualEffectView(material: .underWindowBackground, blendingMode: .behindWindow)
                .ignoresSafeArea()

            if let data = service.data {
                HStack(spacing: 0) {
                    leftSidebar(data: data)
                        .frame(width: 240)

                    Divider()
                        .opacity(0.4)

                    rightContent(data: data)
                }
            } else {
                loadingView
            }
        }
        .frame(minWidth: 760, minHeight: 520)
        .onAppear {
            service.refresh()
        }
    }

    // MARK: - Left Sidebar
    private func leftSidebar(data: FetchData) -> some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 24)

            // Apple Logo
            AppleLogoView(theme: logoTheme, size: 120)
                .padding(.top, 10)

            // OS title
            VStack(spacing: 4) {
                let osItem = data.item(for: "OS")?.value ?? "macOS"
                Text(parseOSName(osItem))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)

                if let hostItem = data.item(for: "Host")?.value {
                    Text(hostItem)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                        .lineLimit(2)
                }
            }

            // Theme selector
            Picker("", selection: $logoTheme) {
                ForEach(LogoTheme.allCases, id: \.self) { theme in
                    Text(theme.rawValue).tag(theme)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 200)
            .padding(.top, 4)

            Spacer()

            // Action Buttons
            VStack(spacing: 8) {
                // Copy Button
                Button(action: handleCopy) {
                    HStack(spacing: 6) {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(copied ? .green : .primary)
                        Text(copied ? "Copied" : "Copy Output")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.bordered)
                .keyboardShortcut("c", modifiers: .command)

                // Refresh Button
                Button(action: handleRefresh) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12, weight: .semibold))
                            .rotationEffect(.degrees(isSpinning ? 360 : 0))
                        Text(service.isLoading ? "Refreshing..." : "Refresh")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.bordered)
                .keyboardShortcut("r", modifiers: .command)
                .disabled(service.isLoading)
            }
            .padding(.horizontal, 24)

            // App footer info
            HStack(spacing: 4) {
                Text("xfetch")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.8))
                Text("•")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary.opacity(0.4))
                Text("System Fetch")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.secondary.opacity(0.8))
            }
            .padding(.bottom, 16)
        }
        .padding(.horizontal, 10)
    }

    // MARK: - Right Content Area
    private func rightContent(data: FetchData) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header: User@Host
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(data.user)
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(.cyan)

                Text("@")
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(.secondary.opacity(0.7))

                Text(data.host)
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)

                Spacer()

                if let uptime = data.item(for: "Uptime")?.value {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 11))
                        Text(uptime)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(Color.primary.opacity(0.06))
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 10)

            // Divider under title
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.cyan.opacity(0.7), Color.blue.opacity(0.4), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1.5)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

            // Spec Rows
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 2) {
                    ForEach(data.items) { item in
                        FetchRowView(item: item)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            }

            Spacer(minLength: 8)

            // Palette at bottom
            VStack(spacing: 6) {
                Divider()
                    .opacity(0.3)
                    .padding(.horizontal, 20)

                ColorPaletteView()
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                    .padding(.top, 4)
            }
        }
    }

    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Gathering System Info...")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers
    private func parseOSName(_ osStr: String) -> String {
        if osStr.contains("macOS") {
            let components = osStr.components(separatedBy: " ")
            if components.count >= 2 {
                return "\(components[0]) \(components[1])"
            }
        }
        return osStr
    }

    private func handleRefresh() {
        withAnimation(.linear(duration: 0.6)) {
            isSpinning = true
        }
        service.refresh()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            isSpinning = false
        }
    }

    private func handleCopy() {
        service.copyToClipboard()
        withAnimation {
            copied = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                copied = false
            }
        }
    }
}
