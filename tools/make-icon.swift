// Renders Magpie's app icon at every size the asset catalog needs.
// Usage: swift tools/make-icon.swift <AppIcon.appiconset dir> [beta]
import AppKit

let args = CommandLine.arguments
let outDir = URL(fileURLWithPath: args[1])
let isBeta = args.count > 2 && args[2] == "beta"

func color(_ hex: UInt32, _ a: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 0xff) / 255, green: CGFloat((hex >> 8) & 0xff) / 255, blue: CGFloat(hex & 0xff) / 255, alpha: a)
}

func drawIcon(in ctx: CGContext, size s: CGFloat) {
    let u = s / 1024
    // Squircle-ish body on the macOS icon grid (824pt body on a 1024 canvas).
    let body = CGRect(x: 100 * u, y: 100 * u, width: 824 * u, height: 824 * u)
    let bodyPath = NSBezierPath(roundedRect: body, xRadius: 186 * u, yRadius: 186 * u)
    
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.35)
    shadow.shadowBlurRadius = 24 * u
    shadow.shadowOffset = NSSize(width: 0, height: -10 * u)
    shadow.set()
    (isBeta ? color(0xB4561C) : color(0x1E2470)).setFill()
    bodyPath.fill()
    NSGraphicsContext.restoreGraphicsState()
    
    NSGraphicsContext.saveGraphicsState()
    bodyPath.addClip()
    let bg = isBeta
        ? NSGradient(colors: [color(0xF6A04D), color(0xD4522A), color(0x8E2A1E)])!
        : NSGradient(colors: [color(0x4F7BFF), color(0x5B3FD8), color(0x1B1F5E)])!
    bg.draw(in: body, angle: -60)
    // Soft glow behind the cards
    NSGradient(colors: [color(0x7FE3FF, 0.45), color(0x7FE3FF, 0)])!
        .draw(fromCenter: NSPoint(x: 600 * u, y: 640 * u), radius: 0, toCenter: NSPoint(x: 600 * u, y: 640 * u), radius: 420 * u, options: [])
    
    // Fanned stack of clipping cards
    let card = CGRect(x: -210 * u, y: -150 * u, width: 420 * u, height: 300 * u)
    let cards: [(angle: CGFloat, dx: CGFloat, dy: CGFloat, alpha: CGFloat)] = [(7, 56, 56, 0.3), (1, 26, 26, 0.55), (-5, -10, -10, 1)]
    for (i, c) in cards.enumerated() {
        NSGraphicsContext.saveGraphicsState()
        let t = NSAffineTransform()
        t.translateX(by: 505 * u + c.dx * u, yBy: 470 * u + c.dy * u)
        t.rotate(byDegrees: c.angle)
        t.concat()
        let path = NSBezierPath(roundedRect: card, xRadius: 44 * u, yRadius: 44 * u)
        let sh = NSShadow()
        sh.shadowColor = NSColor.black.withAlphaComponent(0.28)
        sh.shadowBlurRadius = 30 * u
        sh.shadowOffset = NSSize(width: 0, height: -14 * u)
        sh.set()
        NSColor.white.withAlphaComponent(c.alpha).setFill()
        path.fill()
        if i == cards.count - 1 {
            NSShadow().set()
            // Text lines on the front card
            let widths: [CGFloat] = [300, 240, 270, 170]
            for (j, w) in widths.enumerated() {
                let line = CGRect(x: card.minX + 52 * u, y: card.maxY - (78 + CGFloat(j) * 52) * u, width: w * u, height: 24 * u)
                (j == 0 ? color(0x5B3FD8, 0.85) : color(0x1E2470, 0.22)).setFill()
                NSBezierPath(roundedRect: line, xRadius: 12 * u, yRadius: 12 * u).fill()
            }
        }
        NSGraphicsContext.restoreGraphicsState()
    }
    
    // The shiny thing: a four point spark in magpie-tail teal
    func spark(center: NSPoint, r: CGFloat) -> NSBezierPath {
        let p = NSBezierPath()
        let inner = r * 0.2
        for k in 0..<8 {
            let a = CGFloat(k) * .pi / 4 + .pi / 2
            let rr = k % 2 == 0 ? r : inner
            let pt = NSPoint(x: center.x + cos(a) * rr, y: center.y + sin(a) * rr)
            k == 0 ? p.move(to: pt) : p.line(to: pt)
        }
        p.close()
        return p
    }
    NSGraphicsContext.saveGraphicsState()
    let glow = NSShadow()
    glow.shadowColor = color(0x6FF7E8, 0.9)
    glow.shadowBlurRadius = 40 * u
    glow.set()
    let big = spark(center: NSPoint(x: 735 * u, y: 715 * u), r: 120 * u)
    NSGradient(colors: [color(0xFFFFFF), color(0x8CFFF0), color(0x2BC4E8)])!.draw(in: big, angle: -45)
    let small = spark(center: NSPoint(x: 820 * u, y: 560 * u), r: 48 * u)
    NSGradient(colors: [color(0xFFFFFF), color(0x8CFFF0)])!.draw(in: small, angle: -45)
    NSGraphicsContext.restoreGraphicsState()
    
    // Glass sheen across the top
    let sheen = NSBezierPath(ovalIn: CGRect(x: 40 * u, y: 560 * u, width: 944 * u, height: 560 * u))
    NSGradient(colors: [NSColor.white.withAlphaComponent(0.22), NSColor.white.withAlphaComponent(0)])!.draw(in: sheen, angle: -90)
    NSGraphicsContext.restoreGraphicsState()
    
    // Fine rim highlight
    NSColor.white.withAlphaComponent(0.25).setStroke()
    let rim = NSBezierPath(roundedRect: body.insetBy(dx: 2 * u, dy: 2 * u), xRadius: 184 * u, yRadius: 184 * u)
    rim.lineWidth = 3 * u
    rim.stroke()
}

func render(_ px: Int) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    drawIcon(in: NSGraphicsContext.current!.cgContext, size: CGFloat(px))
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

for px in [16, 32, 64, 128, 256, 512, 1024] {
    try! render(px).write(to: outDir.appendingPathComponent("\(px).png"))
}
print("rendered icons into \(outDir.path)")
