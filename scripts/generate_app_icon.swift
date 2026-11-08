import AppKit
import Foundation

func generateIcon(size: Int) -> NSImage {
    let s = CGFloat(size)
    let image = NSImage(size: NSSize(width: s, height: s))
    image.lockFocus()
    let ctx = NSGraphicsContext.current!.cgContext

    // Rounded macOS Squircle background
    let corner = s * 0.2237
    let rect = NSRect(x: s * 0.05, y: s * 0.05, width: s * 0.9, height: s * 0.9)
    let path = NSBezierPath(roundedRect: rect, xRadius: corner, yRadius: corner)

    // Dark sleek gradient
    let grad = NSGradient(
        starting: NSColor(red: 0.14, green: 0.15, blue: 0.18, alpha: 1.0),
        ending: NSColor(red: 0.08, green: 0.09, blue: 0.11, alpha: 1.0)
    )!
    grad.draw(in: path, angle: -45)

    // Outer subtle border
    path.lineWidth = max(1.0, s * 0.015)
    NSColor(white: 1.0, alpha: 0.18).setStroke()
    path.stroke()

    // Inner subtle sheen
    let innerRect = rect.insetBy(dx: s * 0.02, dy: s * 0.02)
    let innerPath = NSBezierPath(roundedRect: innerRect, xRadius: corner * 0.9, yRadius: corner * 0.9)
    innerPath.lineWidth = max(0.5, s * 0.008)
    NSColor(white: 1.0, alpha: 0.06).setStroke()
    innerPath.stroke()

    // Draw high-resolution vector Apple logo
    let logoPt = s * 0.52
    let config = NSImage.SymbolConfiguration(pointSize: logoPt, weight: .regular)
    if let apple = NSImage(systemSymbolName: "applelogo", accessibilityDescription: nil)?.withSymbolConfiguration(config) {
        let symSize = apple.size
        let logoRect = NSRect(
            x: (s - symSize.width) / 2,
            y: (s - symSize.height) / 2 + s * 0.01,
            width: symSize.width,
            height: symSize.height
        )

        ctx.saveGState()
        if let cgImage = apple.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            ctx.clip(to: logoRect, mask: cgImage)

            // Draw 6 vintage rainbow bands (bottom to top in flipped/standard coords)
            let bandH = symSize.height / 6.0
            let rainbowColors: [NSColor] = [
                NSColor(red: 0.00, green: 0.53, blue: 0.81, alpha: 1.0), // Blue
                NSColor(red: 0.59, green: 0.22, blue: 0.60, alpha: 1.0), // Purple
                NSColor(red: 0.88, green: 0.22, blue: 0.18, alpha: 1.0), // Red
                NSColor(red: 0.95, green: 0.42, blue: 0.15, alpha: 1.0), // Orange
                NSColor(red: 0.97, green: 0.71, blue: 0.16, alpha: 1.0), // Yellow
                NSColor(red: 0.38, green: 0.73, blue: 0.27, alpha: 1.0)  // Green
            ]
            for (i, c) in rainbowColors.enumerated() {
                c.setFill()
                let bRect = NSRect(x: logoRect.minX, y: logoRect.minY + CGFloat(i) * bandH, width: logoRect.width, height: bandH + 0.5)
                bRect.fill()
            }
        }
        ctx.restoreGState()
    }

    image.unlockFocus()
    return image
}

func savePNG(_ image: NSImage, to path: String) {
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
        fatalError("Failed to convert image to PNG")
    }
    try! png.write(to: URL(fileURLWithPath: path))
}

let iconsetDir = "/tmp/xfetch.iconset"
try? FileManager.default.removeItem(atPath: iconsetDir)
try! FileManager.default.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

let iconSizes: [(String, Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for (name, size) in iconSizes {
    let img = generateIcon(size: size)
    savePNG(img, to: "\(iconsetDir)/\(name)")
}

// Generate AppIcon.png (512x512)
let appIcon512 = generateIcon(size: 512)
savePNG(appIcon512, to: "Resources/AppIcon.png")

// Compile .icns
let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
task.arguments = ["-c", "icns", iconsetDir, "-o", "Resources/AppIcon.icns"]
try! task.run()
task.waitUntilExit()

print("✅ Generated Resources/AppIcon.icns and Resources/AppIcon.png successfully!")

