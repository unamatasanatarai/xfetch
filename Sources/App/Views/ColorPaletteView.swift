import SwiftUI

public struct ColorPaletteView: View {
    private struct PaletteColor: Identifiable {
        let id: String
        let name: String
        let color: Color
    }

    private let standardColors: [PaletteColor] = [
        PaletteColor(id: "black", name: "Black", color: Color(red: 0.16, green: 0.17, blue: 0.20)),
        PaletteColor(id: "red", name: "Red", color: Color(red: 0.92, green: 0.32, blue: 0.31)),
        PaletteColor(id: "green", name: "Green", color: Color(red: 0.33, green: 0.76, blue: 0.41)),
        PaletteColor(id: "yellow", name: "Yellow", color: Color(red: 0.95, green: 0.77, blue: 0.26)),
        PaletteColor(id: "blue", name: "Blue", color: Color(red: 0.31, green: 0.56, blue: 0.96)),
        PaletteColor(id: "magenta", name: "Magenta", color: Color(red: 0.84, green: 0.44, blue: 0.84)),
        PaletteColor(id: "cyan", name: "Cyan", color: Color(red: 0.34, green: 0.80, blue: 0.82)),
        PaletteColor(id: "white", name: "White", color: Color(red: 0.88, green: 0.90, blue: 0.92))
    ]

    private let brightColors: [PaletteColor] = [
        PaletteColor(id: "br_black", name: "Bright Black", color: Color(red: 0.36, green: 0.38, blue: 0.42)),
        PaletteColor(id: "br_red", name: "Bright Red", color: Color(red: 1.00, green: 0.45, blue: 0.45)),
        PaletteColor(id: "br_green", name: "Bright Green", color: Color(red: 0.45, green: 0.90, blue: 0.55)),
        PaletteColor(id: "br_yellow", name: "Bright Yellow", color: Color(red: 1.00, green: 0.88, blue: 0.40)),
        PaletteColor(id: "br_blue", name: "Bright Blue", color: Color(red: 0.48, green: 0.70, blue: 1.00)),
        PaletteColor(id: "br_magenta", name: "Bright Magenta", color: Color(red: 0.95, green: 0.58, blue: 0.95)),
        PaletteColor(id: "br_cyan", name: "Bright Cyan", color: Color(red: 0.52, green: 0.92, blue: 0.95)),
        PaletteColor(id: "br_white", name: "Bright White", color: Color(red: 0.98, green: 0.98, blue: 1.00))
    ]

    public init() {}

    public var body: some View {
        VStack(spacing: 5) {
            renderRow(colors: standardColors)
            renderRow(colors: brightColors)
        }
        .padding(.vertical, 4)
    }

    private func renderRow(colors: [PaletteColor]) -> some View {
        HStack(spacing: 6) {
            ForEach(colors) { item in
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(item.color)
                    .frame(height: 12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                    )
                    .help(item.name)
            }
        }
    }
}

