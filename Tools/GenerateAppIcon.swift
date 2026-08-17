import AppKit
import CoreGraphics

let size = 1024
let ctx = CGContext(
    data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
    space: CGColorSpace(name: CGColorSpace.sRGB)!,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
)!

let full = CGRect(x: 0, y: 0, width: size, height: size)

// Dark backdrop so the gold coin pops on the watch face.
ctx.setFillColor(CGColor(red: 0.07, green: 0.08, blue: 0.11, alpha: 1))
ctx.fill(full)

let cs = CGColorSpace(name: CGColorSpace.sRGB)!
let center = CGPoint(x: 512, y: 512)

// Outer rim.
let rim = CGGradient(colorsSpace: cs, colors: [
    CGColor(red: 0.99, green: 0.85, blue: 0.42, alpha: 1),
    CGColor(red: 0.66, green: 0.47, blue: 0.09, alpha: 1),
] as CFArray, locations: [0, 1])!
ctx.saveGState()
ctx.addEllipse(in: CGRect(x: 112, y: 112, width: 800, height: 800))
ctx.clip()
ctx.drawLinearGradient(rim, start: CGPoint(x: 200, y: 900), end: CGPoint(x: 830, y: 150), options: [])
ctx.restoreGState()

// Inner face.
let face = CGGradient(colorsSpace: cs, colors: [
    CGColor(red: 1.00, green: 0.90, blue: 0.55, alpha: 1),
    CGColor(red: 0.80, green: 0.60, blue: 0.16, alpha: 1),
] as CFArray, locations: [0, 1])!
ctx.saveGState()
ctx.addEllipse(in: CGRect(x: 168, y: 168, width: 688, height: 688))
ctx.clip()
ctx.drawLinearGradient(face, start: CGPoint(x: 250, y: 840), end: CGPoint(x: 780, y: 210), options: [])
ctx.restoreGState()

// "H" glyph.
let glyph = NSAttributedString(string: "H", attributes: [
    .font: NSFont(name: "Georgia-Bold", size: 460) ?? NSFont.boldSystemFont(ofSize: 460),
    .foregroundColor: NSColor(srgbRed: 0.30, green: 0.20, blue: 0.02, alpha: 1),
])
let gfx = NSGraphicsContext(cgContext: ctx, flipped: false)
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = gfx
let bounds = glyph.size()
glyph.draw(at: CGPoint(x: center.x - bounds.width / 2, y: center.y - bounds.height / 2))
NSGraphicsContext.restoreGraphicsState()

let image = ctx.makeImage()!
let rep = NSBitmapImageRep(cgImage: image)
let png = rep.representation(using: .png, properties: [:])!
try png.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
print("wrote \(png.count) bytes")
