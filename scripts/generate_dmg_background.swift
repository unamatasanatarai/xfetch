import AppKit

func generateDMGBackground(scale: CGFloat, outputPath: String) {
    let ptWidth: CGFloat = 660
    let ptHeight: CGFloat = 400
    let pxWidth = Int(ptWidth * scale)
    let pxHeight = Int(ptHeight * scale)
    
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pxWidth,
        pixelsHigh: pxHeight,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: pxWidth * 4,
        bitsPerPixel: 32
    )!
    rep.size = NSSize(width: ptWidth, height: ptHeight)
    
    NSGraphicsContext.saveGraphicsState()
    guard let ctx = NSGraphicsContext(bitmapImageRep: rep) else {
        fatalError("Failed to create NSGraphicsContext")
    }
    NSGraphicsContext.current = ctx
    let cg = ctx.cgContext
    
    // Invert coordinate system to match top-left (0,0)
    cg.translateBy(x: 0, y: ptHeight)
    cg.scaleBy(x: 1.0, y: -1.0)
    
    // 1. Sleek dark midnight gradient background
    let bgGrad = NSGradient(
        starting: NSColor(red: 0.12, green: 0.13, blue: 0.16, alpha: 1.0),
        ending: NSColor(red: 0.07, green: 0.08, blue: 0.09, alpha: 1.0)
    )!
    bgGrad.draw(in: CGRect(x: 0, y: 0, width: ptWidth, height: ptHeight), angle: 90)
    
    // 2. Subtle ambient glows
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let glowColors = [
        NSColor(red: 0.0, green: 0.55, blue: 0.95, alpha: 0.12).cgColor,
        NSColor(red: 0.0, green: 0.55, blue: 0.95, alpha: 0.0).cgColor
    ] as CFArray
    if let radialGrad = CGGradient(colorsSpace: colorSpace, colors: glowColors, locations: [0.0, 1.0]) {
        cg.drawRadialGradient(
            radialGrad,
            startCenter: CGPoint(x: ptWidth / 2, y: 195),
            startRadius: 0,
            endCenter: CGPoint(x: ptWidth / 2, y: 195),
            endRadius: 280,
            options: []
        )
    }

    // 3. Perimeter hairline border & top highlight sheen
    let border = NSBezierPath(rect: CGRect(x: 0.5, y: 0.5, width: ptWidth - 1, height: ptHeight - 1))
    NSColor(white: 1.0, alpha: 0.10).setStroke()
    border.lineWidth = 1.0
    border.stroke()

    let sheen = NSBezierPath()
    sheen.move(to: CGPoint(x: 1, y: 1))
    sheen.line(to: CGPoint(x: ptWidth - 1, y: 1))
    NSColor(white: 1.0, alpha: 0.25).setStroke()
    sheen.lineWidth = 1.0
    sheen.stroke()

    let yCenter: CGFloat = 200

    // 4. Icon Pedestals / Drop targets (subtle rounded glass plates)
    let leftPedestal = NSBezierPath(roundedRect: CGRect(x: 180 - 64, y: yCenter - 64, width: 128, height: 128), xRadius: 26, yRadius: 26)
    NSColor(white: 1.0, alpha: 0.035).setFill()
    leftPedestal.fill()
    NSColor(white: 1.0, alpha: 0.08).setStroke()
    leftPedestal.lineWidth = 1.0
    leftPedestal.stroke()

    let rightPedestal = NSBezierPath(roundedRect: CGRect(x: 480 - 64, y: yCenter - 64, width: 128, height: 128), xRadius: 26, yRadius: 26)
    NSColor(white: 1.0, alpha: 0.035).setFill()
    rightPedestal.fill()
    NSColor(white: 1.0, alpha: 0.08).setStroke()
    rightPedestal.lineWidth = 1.0
    rightPedestal.stroke()

    // 5. Hairline dashed trajectory guide between icons
    let track = NSBezierPath()
    track.move(to: CGPoint(x: 248, y: yCenter))
    track.line(to: CGPoint(x: 295, y: yCenter))
    track.move(to: CGPoint(x: 365, y: yCenter))
    track.line(to: CGPoint(x: 412, y: yCenter))
    let pattern: [CGFloat] = [3, 4]
    track.setLineDash(pattern, count: 2, phase: 0)
    track.lineWidth = 1.5
    NSColor(red: 0.0, green: 0.65, blue: 1.0, alpha: 0.40).setStroke()
    track.stroke()

    // 6. Floating action capsule badge (x=330, y=200)
    let pillRect = CGRect(x: 330 - 30, y: yCenter - 18, width: 60, height: 36)
    let pillPath = NSBezierPath(roundedRect: pillRect, xRadius: 18, yRadius: 18)

    cg.saveGState()
    cg.setShadow(offset: CGSize(width: 0, height: 4), blur: 12, color: NSColor.black.withAlphaComponent(0.40).cgColor)
    NSColor(red: 0.16, green: 0.18, blue: 0.22, alpha: 1.0).setFill()
    pillPath.fill()
    cg.restoreGState()

    NSColor(white: 1.0, alpha: 0.18).setStroke()
    pillPath.lineWidth = 1.0
    pillPath.stroke()

    // Directional Arrow inside capsule
    let arrow = NSBezierPath()
    arrow.move(to: CGPoint(x: 318, y: yCenter))
    arrow.line(to: CGPoint(x: 342, y: yCenter))
    arrow.move(to: CGPoint(x: 334, y: yCenter - 6))
    arrow.line(to: CGPoint(x: 342, y: yCenter))
    arrow.line(to: CGPoint(x: 334, y: yCenter + 6))
    arrow.lineWidth = 2.4
    arrow.lineCapStyle = .round
    arrow.lineJoinStyle = .round
    NSColor(red: 0.35, green: 0.78, blue: 1.0, alpha: 1.0).setStroke()
    arrow.stroke()

    // 7. Signature Fastfetch 16-Color Palette Pills (Bottom, 2 rows)
    let standardColors: [NSColor] = [
        NSColor(red: 0.16, green: 0.17, blue: 0.20, alpha: 1.0),
        NSColor(red: 0.92, green: 0.32, blue: 0.31, alpha: 1.0),
        NSColor(red: 0.33, green: 0.76, blue: 0.41, alpha: 1.0),
        NSColor(red: 0.95, green: 0.77, blue: 0.26, alpha: 1.0),
        NSColor(red: 0.31, green: 0.56, blue: 0.96, alpha: 1.0),
        NSColor(red: 0.84, green: 0.44, blue: 0.84, alpha: 1.0),
        NSColor(red: 0.34, green: 0.80, blue: 0.82, alpha: 1.0),
        NSColor(red: 0.88, green: 0.90, blue: 0.92, alpha: 1.0)
    ]
    let brightColors: [NSColor] = [
        NSColor(red: 0.36, green: 0.38, blue: 0.42, alpha: 1.0),
        NSColor(red: 1.00, green: 0.45, blue: 0.45, alpha: 1.0),
        NSColor(red: 0.45, green: 0.90, blue: 0.55, alpha: 1.0),
        NSColor(red: 1.00, green: 0.88, blue: 0.40, alpha: 1.0),
        NSColor(red: 0.48, green: 0.70, blue: 1.00, alpha: 1.0),
        NSColor(red: 0.95, green: 0.58, blue: 0.95, alpha: 1.0),
        NSColor(red: 0.52, green: 0.92, blue: 0.95, alpha: 1.0),
        NSColor(red: 0.98, green: 0.98, blue: 1.00, alpha: 1.0)
    ]
    let pillW: CGFloat = 18
    let pillH: CGFloat = 6
    let spacing: CGFloat = 5
    let totalW = CGFloat(standardColors.count) * pillW + CGFloat(standardColors.count - 1) * spacing
    let startX = (ptWidth - totalW) / 2
    let paletteY1: CGFloat = 345
    let paletteY2: CGFloat = 355

    for (i, c) in standardColors.enumerated() {
        let r = CGRect(x: startX + CGFloat(i) * (pillW + spacing), y: paletteY1, width: pillW, height: pillH)
        let p = NSBezierPath(roundedRect: r, xRadius: 3, yRadius: 3)
        c.setFill()
        p.fill()
    }
    for (i, c) in brightColors.enumerated() {
        let r = CGRect(x: startX + CGFloat(i) * (pillW + spacing), y: paletteY2, width: pillW, height: pillH)
        let p = NSBezierPath(roundedRect: r, xRadius: 3, yRadius: 3)
        c.setFill()
        p.fill()
    }

    // 8. Mini Rainbow Apple Vector in Header
    let appleSize: CGFloat = 26
    let appleConfig = NSImage.SymbolConfiguration(pointSize: appleSize, weight: .medium)
    if let apple = NSImage(systemSymbolName: "applelogo", accessibilityDescription: nil)?.withSymbolConfiguration(appleConfig) {
        let symSize = apple.size
        let appleRect = NSRect(
            x: (ptWidth - symSize.width) / 2,
            y: 30,
            width: symSize.width,
            height: symSize.height
        )

        cg.saveGState()
        if let cgImage = apple.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            cg.clip(to: appleRect, mask: cgImage)

            let bandH = symSize.height / 6.0
            let rainbowColors: [NSColor] = [
                NSColor(red: 0.38, green: 0.73, blue: 0.27, alpha: 1.0), // Green (top in flipped)
                NSColor(red: 0.97, green: 0.71, blue: 0.16, alpha: 1.0), // Yellow
                NSColor(red: 0.95, green: 0.42, blue: 0.15, alpha: 1.0), // Orange
                NSColor(red: 0.88, green: 0.22, blue: 0.18, alpha: 1.0), // Red
                NSColor(red: 0.59, green: 0.22, blue: 0.60, alpha: 1.0), // Purple
                NSColor(red: 0.00, green: 0.53, blue: 0.81, alpha: 1.0)  // Blue
            ]
            for (i, c) in rainbowColors.enumerated() {
                c.setFill()
                let bRect = NSRect(x: appleRect.minX, y: appleRect.minY + CGFloat(i) * bandH, width: appleRect.width, height: bandH + 0.5)
                bRect.fill()
            }
        }
        cg.restoreGState()
    }

    // Flip back for text rendering
    cg.translateBy(x: 0, y: ptHeight)
    cg.scaleBy(x: 1.0, y: -1.0)

    // 9. Top Header Branding
    let titleStyle = NSMutableParagraphStyle()
    titleStyle.alignment = .center
    let brandAttrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 18, weight: .bold),
        .foregroundColor: NSColor.white,
        .paragraphStyle: titleStyle,
        .kern: 1.2
    ]
    let brandStr = NSAttributedString(string: "xfetch", attributes: brandAttrs)
    brandStr.draw(in: CGRect(x: 0, y: ptHeight - 65, width: ptWidth, height: 22))

    let subAttrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 11, weight: .medium),
        .foregroundColor: NSColor(red: 0.35, green: 0.78, blue: 1.0, alpha: 0.90),
        .paragraphStyle: titleStyle,
        .kern: 0.8
    ]
    let subStr = NSAttributedString(string: "Native System Fetch for macOS", attributes: subAttrs)
    subStr.draw(in: CGRect(x: 0, y: ptHeight - 84, width: ptWidth, height: 16))

    // 10. Instruction Typography (under icons)
    let pStyle = NSMutableParagraphStyle()
    pStyle.alignment = .center
    let titleAttrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 10, weight: .bold),
        .foregroundColor: NSColor(white: 0.65, alpha: 1.0),
        .paragraphStyle: pStyle,
        .kern: 2.0
    ]
    let titleStr = NSAttributedString(string: "DRAG TO APPLICATIONS TO INSTALL", attributes: titleAttrs)
    titleStr.draw(in: CGRect(x: 0, y: ptHeight - 302, width: ptWidth, height: 16))

    NSGraphicsContext.restoreGraphicsState()
    
    guard let pngData = rep.representation(using: .png, properties: [:]) else {
        fatalError("Failed to convert image to PNG")
    }
    try! pngData.write(to: URL(fileURLWithPath: outputPath))
    print("Generated: \(outputPath) (\(pxWidth)x\(pxHeight))")
}

generateDMGBackground(scale: 1.0, outputPath: "Resources/dmg_background.png")
generateDMGBackground(scale: 2.0, outputPath: "Resources/dmg_background@2x.png")
