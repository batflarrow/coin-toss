// Builds the photographic coin artwork from freely-licensed source images.
//
// Every source below is public domain or CC0 with no attribution required
// (they are credited in CREDITS.md regardless). The originals are large photos
// with wide margins, so this tool finds the coin, crops to it, masks it to a
// disc and writes a watch-sized PNG into the asset catalogue.
//
//     swift Tools/PrepareCoinImages.swift ["CoinToss Watch App/Assets.xcassets/Coins"]
//
import AppKit
import CoreGraphics
import Foundation
import ImageIO

// MARK: - What to build

struct Source {
    let title: String
    let asset: String
}

let manifest = [
    // US one cent — design by the United States Mint, a US government work.
    Source(title: "File:2005 Penny Obv Unc D.png", asset: "us-cent-heads"),
    Source(title: "File:2005 Penny Rev Unc D.png", asset: "us-cent-tails"),

    // Indian one rupee — released CC0 by the photographer.
    Source(title: "File:Indian 1 rupee coin (observe).png", asset: "rupee-heads"),
    Source(title: "File:Indian 1 rupee coin (reverse.png", asset: "rupee-tails"),

    // British five pounds, 1887: Boehm's Jubilee head, Pistrucci's St George.
    // Cleveland Museum of Art open access; both designers died long ago.
    Source(title: "File:Joseph Boehm - Five Pounds (obverse) - 1969.219.a - Cleveland Museum of Art.tif",
           asset: "five-pounds-heads"),
    Source(title: "File:Benedetto Pistrucci - Five Pounds (reverse) - 1969.219.b - Cleveland Museum of Art.jpg",
           asset: "five-pounds-tails"),
]

/// Rendered edge length. The coin draws at ~100pt at its largest, so this
/// covers @2x with room to spare without bloating the app.
let outputSize = 256

let userAgent = "CoinToss-ImagePrep/1.0 (https://github.com/batflarrow/coin-toss)"

// MARK: - Networking

func get(_ url: URL) throws -> Data {
    var request = URLRequest(url: url)
    request.setValue(userAgent, forHTTPHeaderField: "User-Agent")

    var result: Result<Data, Error>!
    let done = DispatchSemaphore(value: 0)
    URLSession.shared.dataTask(with: request) { data, _, error in
        result = error.map { .failure($0) } ?? .success(data ?? Data())
        done.signal()
    }.resume()
    done.wait()

    return try result.get()
}

/// Commons stores files under a hashed path, so the URL has to be looked up.
func resolveURL(title: String) throws -> URL {
    var components = URLComponents(string: "https://commons.wikimedia.org/w/api.php")!
    components.queryItems = [
        .init(name: "action", value: "query"),
        .init(name: "format", value: "json"),
        .init(name: "prop", value: "imageinfo"),
        .init(name: "iiprop", value: "url"),
        .init(name: "titles", value: title),
    ]

    let json = try JSONSerialization.jsonObject(with: get(components.url!)) as? [String: Any]
    guard let query = json?["query"] as? [String: Any],
          let pages = query["pages"] as? [String: Any],
          let page = pages.values.first as? [String: Any],
          let info = (page["imageinfo"] as? [[String: Any]])?.first,
          let string = info["url"] as? String,
          let url = URL(string: string.components(separatedBy: "?")[0])
    else { throw Failure("could not resolve \(title)") }

    return url
}

struct Failure: Error, CustomStringConvertible {
    let description: String
    init(_ description: String) { self.description = description }
}

// MARK: - Pixels

/// Redraws into a known RGBA8 layout so the bytes can be inspected directly.
func normalize(_ image: CGImage) throws -> (pixels: [UInt8], width: Int, height: Int) {
    let width = image.width, height = image.height
    var pixels = [UInt8](repeating: 0, count: width * height * 4)

    guard let context = CGContext(
        data: &pixels, width: width, height: height,
        bitsPerComponent: 8, bytesPerRow: width * 4,
        space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { throw Failure("could not build a bitmap context") }

    context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    return (pixels, width, height)
}

/// Finds the coin, whether it sits on transparency or on a plain backdrop.
///
/// Corners are sampled to learn the background; a pixel counts as coin when it
/// is opaque and far enough from that background colour. Rows and columns need
/// a handful of coin pixels to count, which keeps stray speckles out of the box.
func coinBounds(_ image: CGImage) throws -> CGRect {
    let (pixels, width, height) = try normalize(image)

    func sample(_ x: Int, _ y: Int) -> (r: Double, g: Double, b: Double, a: Double) {
        let i = (y * width + x) * 4
        return (Double(pixels[i]) / 255, Double(pixels[i + 1]) / 255,
                Double(pixels[i + 2]) / 255, Double(pixels[i + 3]) / 255)
    }

    // Average a small patch in each corner.
    var background = (r: 0.0, g: 0.0, b: 0.0, a: 0.0)
    let patch = max(2, min(width, height) / 100)
    var samples = 0
    for (cx, cy) in [(0, 0), (width - patch - 1, 0), (0, height - patch - 1),
                     (width - patch - 1, height - patch - 1)] {
        for dy in 0..<patch {
            for dx in 0..<patch {
                let p = sample(cx + dx, cy + dy)
                background = (background.r + p.r, background.g + p.g,
                              background.b + p.b, background.a + p.a)
                samples += 1
            }
        }
    }
    background = (background.r / Double(samples), background.g / Double(samples),
                  background.b / Double(samples), background.a / Double(samples))

    let backgroundIsClear = background.a < 0.1

    func isCoin(_ x: Int, _ y: Int) -> Bool {
        let p = sample(x, y)
        guard p.a > 0.5 else { return false }
        if backgroundIsClear { return true }

        let distance = ((p.r - background.r) * (p.r - background.r)
            + (p.g - background.g) * (p.g - background.g)
            + (p.b - background.b) * (p.b - background.b)).squareRoot()
        return distance > 0.16
    }

    // Measure each row and column rather than taking an outer bounding box: a
    // drop shadow under the coin would stretch the box and drag backdrop into
    // the crop. The widest row and the tallest column both span the coin's
    // diameter, and a shadow can only ever inflate one of the two — so the
    // smaller of the pair is the honest measurement.
    var rowExtent = [(span: Int, centre: Double)](repeating: (0, 0), count: height)
    var columnExtent = [(span: Int, centre: Double)](repeating: (0, 0), count: width)

    for y in 0..<height {
        var first = -1, last = -1, hits = 0
        for x in 0..<width where isCoin(x, y) {
            if first < 0 { first = x }
            last = x
            hits += 1
        }
        if hits > 3 { rowExtent[y] = (last - first + 1, Double(first + last) / 2) }
    }

    for x in 0..<width {
        var first = -1, last = -1, hits = 0
        for y in 0..<height where isCoin(x, y) {
            if first < 0 { first = y }
            last = y
            hits += 1
        }
        if hits > 3 { columnExtent[x] = (last - first + 1, Double(first + last) / 2) }
    }

    guard let widestRow = rowExtent.max(by: { $0.span < $1.span }),
          let tallestColumn = columnExtent.max(by: { $0.span < $1.span }),
          widestRow.span > 0, tallestColumn.span > 0
    else { throw Failure("no coin found in the image") }

    let diameter = Double(min(widestRow.span, tallestColumn.span))
    let centreX = widestRow.centre
    let centreY = tallestColumn.centre

    return CGRect(
        x: centreX - diameter / 2,
        y: centreY - diameter / 2,
        width: diameter,
        height: diameter
    )
}

/// Crops to a square around the coin and masks it to a disc.
func renderCoin(_ image: CGImage, bounds: CGRect, size: Int) throws -> CGImage {
    // A square centred on the coin, with a hair of margin so the rim survives.
    let side = max(bounds.width, bounds.height) * 1.01
    let square = CGRect(
        x: bounds.midX - side / 2,
        y: bounds.midY - side / 2,
        width: side, height: side
    )

    guard let context = CGContext(
        data: nil, width: size, height: size,
        bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { throw Failure("could not build an output context") }

    context.interpolationQuality = .high
    context.addEllipse(in: CGRect(x: 0, y: 0, width: size, height: size))
    context.clip()

    // Scale the chosen square up to fill the output.
    let scale = Double(size) / side
    context.scaleBy(x: scale, y: scale)
    context.translateBy(x: -square.minX, y: -square.minY)
    context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))

    guard let output = context.makeImage() else { throw Failure("could not render the coin") }
    return output
}

// MARK: - Output

func writeImageset(_ image: CGImage, asset: String, directory: URL) throws {
    let imageset = directory.appendingPathComponent("\(asset).imageset")
    try FileManager.default.createDirectory(at: imageset, withIntermediateDirectories: true)

    let png = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])!
    try png.write(to: imageset.appendingPathComponent("\(asset).png"))

    let contents = """
    {
      "images" : [
        {
          "filename" : "\(asset).png",
          "idiom" : "universal"
        }
      ],
      "info" : {
        "author" : "xcode",
        "version" : 1
      }
    }

    """
    try contents.write(to: imageset.appendingPathComponent("Contents.json"),
                       atomically: true, encoding: .utf8)

    print("  \(asset).png  (\(png.count) bytes)")
}

// MARK: - Entry point

let outputDirectory = URL(fileURLWithPath: CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "CoinToss Watch App/Assets.xcassets/Coins")

try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
try """
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}

""".write(to: outputDirectory.appendingPathComponent("Contents.json"),
          atomically: true, encoding: .utf8)

for source in manifest {
    print("· \(source.asset)")
    let url = try resolveURL(title: source.title)
    let data = try get(url)

    guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil),
          let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
    else { throw Failure("could not decode \(source.title)") }

    let bounds = try coinBounds(image)
    let coin = try renderCoin(image, bounds: bounds, size: outputSize)
    try writeImageset(coin, asset: source.asset, directory: outputDirectory)
}

print("done")
