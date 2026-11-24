// Renders the app icon. Usage: swift scripts/make-icon.swift <out.icns> [preview.png]
import AppKit
import CoreText

func rgb(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: alpha
    )
}

func squircle(in rect: CGRect, exponent n: CGFloat = 5) -> CGPath {
    let path = CGMutablePath()
    let a = rect.width / 2, b = rect.height / 2
    for i in 0...720 {
        let t = CGFloat(i) / 720 * 2 * .pi
        let c = cos(t), s = sin(t)
        let x = rect.midX + a * (c < 0 ? -1 : 1) * pow(abs(c), 2 / n)
        let y = rect.midY + b * (s < 0 ? -1 : 1) * pow(abs(s), 2 / n)
        i == 0 ? path.move(to: CGPoint(x: x, y: y)) : path.addLine(to: CGPoint(x: x, y: y))
    }
    path.closeSubpath()
    return path
}

func fillGradient(_ ctx: CGContext, _ path: CGPath, top: UInt32, bottom: UInt32) {
    let box = path.boundingBox
    let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: [rgb(top), rgb(bottom)] as CFArray, locations: [0, 1])!
    ctx.saveGState()
    ctx.addPath(path)
    ctx.clip()
    ctx.drawLinearGradient(gradient, start: CGPoint(x: box.midX, y: box.maxY), end: CGPoint(x: box.midX, y: box.minY), options: [])
    ctx.restoreGState()
}

func arrowArc(_ ctx: CGContext, center c: CGPoint, radius r: CGFloat, from start: CGFloat, to end: CGFloat) {
    let rad = { (deg: CGFloat) in deg * .pi / 180 }
    ctx.addArc(center: c, radius: r, startAngle: rad(start), endAngle: rad(end), clockwise: false)
    ctx.strokePath()
    let θ = rad(end)
    let p = CGPoint(x: c.x + r * cos(θ), y: c.y + r * sin(θ))
    let tangent = CGPoint(x: -sin(θ), y: cos(θ)), normal = CGPoint(x: cos(θ), y: sin(θ))
    ctx.move(to: CGPoint(x: p.x + tangent.x * 42, y: p.y + tangent.y * 42))
    ctx.addLine(to: CGPoint(x: p.x + normal.x * 32, y: p.y + normal.y * 32))
    ctx.addLine(to: CGPoint(x: p.x - normal.x * 32, y: p.y - normal.y * 32))
    ctx.closePath()
    ctx.fillPath()
}

// Drawn on a 1024pt canvas, origin bottom-left, using Apple's 824pt icon body grid.
func draw(_ ctx: CGContext) {
    let body = squircle(in: CGRect(x: 100, y: 100, width: 824, height: 824))
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -12), blur: 28, color: rgb(0x000000, 0.35))
    ctx.addPath(body)
    ctx.setFillColor(rgb(0x4F6BFF))
    ctx.fillPath()
    ctx.restoreGState()
    fillGradient(ctx, body, top: 0x4F7BFF, bottom: 0x6B3CEB)

    let cap = CGPath(roundedRect: CGRect(x: 252, y: 258, width: 520, height: 520), cornerWidth: 104, cornerHeight: 104, transform: nil)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -18), blur: 36, color: rgb(0x1A0F5C, 0.45))
    ctx.addPath(cap)
    ctx.setFillColor(rgb(0xC9CEEF))
    ctx.fillPath()
    ctx.restoreGState()

    let face = CGPath(roundedRect: CGRect(x: 286, y: 326, width: 452, height: 422), cornerWidth: 78, cornerHeight: 78, transform: nil)
    fillGradient(ctx, face, top: 0xFFFFFF, bottom: 0xEDEFFB)

    let base = NSFont.systemFont(ofSize: 300, weight: .heavy)
    let font = base.fontDescriptor.withDesign(.rounded).flatMap { NSFont(descriptor: $0, size: 300) } ?? base
    let line = CTLineCreateWithAttributedString(NSAttributedString(string: "A", attributes: [
        .font: font,
        .foregroundColor: NSColor(cgColor: rgb(0x3D34D6))!,
    ]))
    let glyph = CTLineGetImageBounds(line, ctx)
    let faceBox = face.boundingBox
    ctx.textPosition = CGPoint(x: faceBox.midX - glyph.width / 2 - glyph.minX, y: faceBox.midY - glyph.height / 2 - glyph.minY)
    CTLineDraw(line, ctx)

    let badgeCenter = CGPoint(x: 724, y: 306)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -8), blur: 18, color: rgb(0x1A0F5C, 0.4))
    ctx.addEllipse(in: CGRect(x: badgeCenter.x - 132, y: badgeCenter.y - 132, width: 264, height: 264))
    ctx.setFillColor(rgb(0xFFFFFF))
    ctx.fillPath()
    ctx.restoreGState()
    let badge = CGPath(ellipseIn: CGRect(x: badgeCenter.x - 114, y: badgeCenter.y - 114, width: 228, height: 228), transform: nil)
    fillGradient(ctx, badge, top: 0xFFA24C, bottom: 0xFF6A2B)

    ctx.setStrokeColor(rgb(0xFFFFFF))
    ctx.setFillColor(rgb(0xFFFFFF))
    ctx.setLineWidth(24)
    ctx.setLineCap(.round)
    arrowArc(ctx, center: badgeCenter, radius: 60, from: 25, to: 145)
    arrowArc(ctx, center: badgeCenter, radius: 60, from: 205, to: 325)
}

func render(size: Int) -> CGImage {
    let ctx = CGContext(
        data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    let scale = CGFloat(size) / 1024
    ctx.scaleBy(x: scale, y: scale)
    draw(ctx)
    return ctx.makeImage()!
}

func writePNG(_ image: CGImage, to url: URL) throws {
    try NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])!.write(to: url)
}

let args = CommandLine.arguments
guard args.count >= 2 else {
    FileHandle.standardError.write("usage: make-icon.swift <out.icns> [preview.png]\n".data(using: .utf8)!)
    exit(1)
}

let iconset = FileManager.default.temporaryDirectory.appendingPathComponent("AppIcon-\(UUID().uuidString).iconset")
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
defer { try? FileManager.default.removeItem(at: iconset) }

for points in [16, 32, 128, 256, 512] {
    try writePNG(render(size: points), to: iconset.appendingPathComponent("icon_\(points)x\(points).png"))
    try writePNG(render(size: points * 2), to: iconset.appendingPathComponent("icon_\(points)x\(points)@2x.png"))
}

let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", iconset.path, "-o", args[1]]
try iconutil.run()
iconutil.waitUntilExit()
guard iconutil.terminationStatus == 0 else { exit(iconutil.terminationStatus) }

if args.count >= 3 {
    try writePNG(render(size: 1024), to: URL(fileURLWithPath: args[2]))
}
