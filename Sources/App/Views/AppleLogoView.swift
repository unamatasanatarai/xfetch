import SwiftUI

public enum LogoTheme: String, CaseIterable, Identifiable, Hashable {
    case retroRainbow = "Rainbow"
    case modernNeon = "Neon"
    case monochrome = "Monochrome"

    public var id: String { rawValue }
}

public struct AppleLogoView: View {
    public var theme: LogoTheme
    public var size: CGFloat

    public init(theme: LogoTheme = .retroRainbow, size: CGFloat = 130) {
        self.theme = theme
        self.size = size
    }

    public var body: some View {
        Group {
            switch theme {
            case .retroRainbow:
                rainbowLogo
            case .modernNeon:
                neonLogo
            case .monochrome:
                monochromeLogo
            }
        }
        .frame(width: size, height: size * 1.2)
        .shadow(color: shadowColor, radius: 10, x: 0, y: 4)
    }

    private var rainbowLogo: some View {
        VStack(spacing: 0) {
            Color(red: 0.38, green: 0.73, blue: 0.27) // Green
            Color(red: 0.97, green: 0.71, blue: 0.16) // Yellow
            Color(red: 0.95, green: 0.42, blue: 0.15) // Orange
            Color(red: 0.88, green: 0.22, blue: 0.18) // Red
            Color(red: 0.59, green: 0.22, blue: 0.60) // Purple
            Color(red: 0.00, green: 0.53, blue: 0.81) // Blue
        }
        .mask(
            Image(systemName: "applelogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
        )
    }

    private var neonLogo: some View {
        LinearGradient(
            colors: [
                Color.cyan,
                Color.blue,
                Color.purple
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .mask(
            Image(systemName: "applelogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
        )
    }

    private var monochromeLogo: some View {
        Image(systemName: "applelogo")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundColor(.primary)
    }

    private var shadowColor: Color {
        switch theme {
        case .retroRainbow:
            return Color.orange.opacity(0.25)
        case .modernNeon:
            return Color.blue.opacity(0.35)
        case .monochrome:
            return Color.primary.opacity(0.12)
        }
    }
}
