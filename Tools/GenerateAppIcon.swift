// Turns the source artwork into an App Store-compliant app icon.
//
//     swift Tools/GenerateAppIcon.swift [source.png] [output.png]
//
// Two rules drive everything here:
//
//   1. Apple rejects app icons that carry an alpha channel, so the output is
//      written as opaque RGB with no alpha at all.
//   2. watchOS masks icons to a circle, so nothing that matters may sit in the
//      corners — and the artwork's own rounded corners are pointless. A small
//      zoom pushes them out of frame so the icon is full-bleed instead of
//      having a translucent border baked in.
//
import AppKit
import CoreGraphics
import Foundation

let sourcePath = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "Tools/icon-source.png"
let outputPath = CommandLine.arguments.count > 2
    ? CommandLine.arguments[2]
    : "CoinToss Watch App/Assets.xcassets/AppIcon.appiconset/AppIcon.png"

let size = 1024

/// Enough to clear the artwork's rounded corners without eating the subject.
let zoom = 1.10

struct Failure: Error, CustomStringConvertible {
    let description: String
    init(_ description: String) { self.description = description }
}

guard let source = NSImage(contentsOfFile: sourcePath)?
    .cgImage(forProposedRect: nil, context: nil, hints: nil)
else { throw Failure("could not read \(sourcePath)") }

// Sample a patch just inside the artwork to pick a backdrop that matches it,
// so any pixel the zoom fails to cover blends in rather than showing a seam.
func averageColour(of image: CGImage) -> (r: Double, g: Double, b: Double) {
    let w = image.width, h = image.height
    var pixels = [UInt8](repeating: 0, count: w * h * 4)
    let ctx = CGContext(
        data: &pixels, width: w, height: h,
        bitsPerComponent: 8, bytesPerRow: w * 4,
        space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))

    var r = 0.0, g = 0.0, b = 0.0, n = 0.0
    let inset = Int(Double(min(w, h)) * 0.22)
    for y in stride(from: inset, to: h - inset, by: 16) {
        for x in stride(from: inset, to: w - inset, by: 16) {
            let i = (y * w + x) * 4
            guard pixels[i + 3] > 200 else { continue }
            r += Double(pixels[i]); g += Double(pixels[i + 1]); b += Double(pixels[i + 2]); n += 1
        }
    }
    guard n > 0 else { return (0.85, 0.78, 0.62) }
    return (r / n / 255, g / n / 255, b / n / 255)
}

let backdrop = averageColour(of: source)

// noneSkipLast => the bitmap has no alpha channel, which is what Apple wants.
guard let context = CGContext(
    data: nil, width: size, height: size,
    bitsPerComponent: 8, bytesPerRow: 0,
    space: CGColorSpace(name: CGColorSpace.sRGB)!,
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
) else { throw Failure("could not create an opaque context") }

context.setFillColor(CGColor(red: backdrop.r, green: backdrop.g, blue: backdrop.b, alpha: 1))
context.fill(CGRect(x: 0, y: 0, width: size, height: size))

context.interpolationQuality = .high

// Aspect-fill the square, then zoom past the artwork's rounded corners.
let scale = Double(size) / Double(min(source.width, source.height)) * zoom
let drawWidth = Double(source.width) * scale
let drawHeight = Double(source.height) * scale
context.draw(source, in: CGRect(
    x: (Double(size) - drawWidth) / 2,
    y: (Double(size) - drawHeight) / 2,
    width: drawWidth,
    height: drawHeight
))

guard let output = context.makeImage() else { throw Failure("could not render the icon") }

let rep = NSBitmapImageRep(cgImage: output)
guard let png = rep.representation(using: .png, properties: [:]) else {
    throw Failure("could not encode PNG")
}
try png.write(to: URL(fileURLWithPath: outputPath))

print("wrote \(outputPath)")
print("  \(size)x\(size), \(png.count) bytes, alpha: \(rep.hasAlpha)")
