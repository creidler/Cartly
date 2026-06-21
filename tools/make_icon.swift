// Generates the 1024×1024 App Store icon for Cartly.
// Usage: swift tools/make_icon.swift
import AppKit

let size = 1024
let rect = CGRect(x: 0, y: 0, width: size, height: size)

guard let ctx = CGContext(
    data: nil, width: size, height: size,
    bitsPerComponent: 8, bytesPerRow: 0,
    space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else { fatalError("ctx") }

// Background gradient (fresh green → teal).
let colors = [
    CGColor(red: 0.16, green: 0.62, blue: 0.40, alpha: 1),
    CGColor(red: 0.10, green: 0.44, blue: 0.42, alpha: 1),
] as CFArray
let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                          colors: colors, locations: [0, 1])!
ctx.drawLinearGradient(gradient,
                       start: CGPoint(x: 0, y: size),
                       end: CGPoint(x: size, y: 0),
                       options: [])

// Soft highlight blob, top-left.
ctx.saveGState()
ctx.setBlendMode(.softLight)
ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.30))
ctx.fillEllipse(in: CGRect(x: -180, y: 560, width: 760, height: 760))
ctx.restoreGState()

// Draw an SF Symbol cart, centered, in white.
func drawSymbol(_ name: String, scale: CGFloat) {
    let config = NSImage.SymbolConfiguration(pointSize: CGFloat(size) * scale, weight: .semibold)
    guard let symbol = NSImage(systemSymbolName: name, accessibilityDescription: nil)?
        .withSymbolConfiguration(config) else { return }

    let tinted = NSImage(size: symbol.size)
    tinted.lockFocus()
    NSColor.white.set()
    let r = NSRect(origin: .zero, size: symbol.size)
    symbol.draw(in: r)
    r.fill(using: .sourceAtop)
    tinted.unlockFocus()

    guard let cg = tinted.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return }
    let w = symbol.size.width, h = symbol.size.height
    let dest = CGRect(x: (CGFloat(size) - w) / 2,
                      y: (CGFloat(size) - h) / 2 + CGFloat(size) * 0.02,
                      width: w, height: h)
    ctx.setShadow(offset: CGSize(width: 0, height: -10),
                  blur: 30,
                  color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.18))
    ctx.draw(cg, in: dest)
}

drawSymbol("cart.fill", scale: 0.46)

guard let image = ctx.makeImage() else { fatalError("image") }
let bitmap = NSBitmapImageRep(cgImage: image)
guard let png = bitmap.representation(using: .png, properties: [:]) else { fatalError("png") }

let out = URL(fileURLWithPath: "Cartly/Assets.xcassets/AppIcon.appiconset/AppIcon1024.png")
try! png.write(to: out)
print("Wrote \(out.path)")
