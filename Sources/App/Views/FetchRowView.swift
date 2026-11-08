import SwiftUI

public struct FetchRowView: View {
    public let item: FetchItem

    public init(item: FetchItem) {
        self.item = item
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 10) {
            // Icon Tile
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(item.accentColor.opacity(0.15))
                    .frame(width: 24, height: 24)

                Image(systemName: item.iconName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(item.accentColor)
            }

            // Key Label
            Text(item.displayKey)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.primary)
                .frame(width: 115, alignment: .leading)
                .lineLimit(1)

            // Colon separator
            Text(":")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.secondary.opacity(0.6))

            // Value Label
            Text(item.displayValue)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.secondary)
                .lineLimit(2)
                .textSelection(.enabled)

            Spacer(minLength: 8)

            // Percentage Meter (if available)
            if let pct = item.percentage {
                HStack(spacing: 6) {
                    // Mini progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.primary.opacity(0.08))
                                .frame(height: 6)

                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [item.accentColor, item.accentColor.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(geo.size.width * CGFloat(pct), 6), height: 6)
                        }
                    }
                    .frame(width: 65, height: 6)

                    Text(String(format: "%.0f%%", pct * 100.0))
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                        .frame(width: 34, alignment: .trailing)
                }
            }
        }
        .padding(.vertical, 3)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.clear)
        )
    }
}
