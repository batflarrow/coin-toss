import SwiftUI

/// What a coin face shows.
///
/// Drawn coins stay crisp at any size and cost nothing to ship; photographic
/// coins are real currency, and are limited to public-domain and CC0 source
/// images (see CREDITS.md) so the app carries no attribution obligations.
enum CoinArt: Hashable, Sendable {
    /// An SF Symbol engraved on a drawn disc, e.g. `crown.fill`.
    case symbol(String)
    /// A short piece of text engraved on a drawn disc, e.g. `H`.
    case letter(String)
    /// An asset-catalogue image that *is* the coin, already masked to a disc.
    case photo(String)
}

/// A coin the user can toss. Purely presentational — the odds never change.
struct CoinStyle: Identifiable, Hashable, Sendable {
    let id: String
    let name: String

    /// Outer edge, darker than the face. Also tints the tails tally tag.
    let rim: Color
    /// The flat of the coin. Also tints the heads tally tag.
    let face: Color
    /// Colour of the engraving on drawn coins.
    let engraving: Color

    let heads: CoinArt
    let tails: CoinArt

    func art(for coinFace: CoinFace) -> CoinArt {
        switch coinFace {
        case .heads: heads
        case .tails: tails
        }
    }

    /// True when both faces are photographs of a real coin.
    var isPhotographic: Bool {
        if case .photo = heads, case .photo = tails { return true }
        return false
    }

    /// Tint for the heads tally tag. The coin's face is already light enough
    /// to read against the watch's black background.
    var headsTint: Color { face }

    /// Tint for the tails tally tag. The rim is the coin's darker metal, which
    /// on a black background is close to unreadable, so it is lifted toward
    /// white just far enough to stay legible while still reading as the rim.
    var tailsTint: Color { rim.mix(with: .white, by: 0.45) }

    /// Asset names this style needs at runtime.
    var photoAssets: [String] {
        [heads, tails].compactMap {
            if case .photo(let name) = $0 { return name }
            return nil
        }
    }
}

extension CoinStyle {
    private static func rgb(_ r: Double, _ g: Double, _ b: Double) -> Color {
        Color(red: r, green: g, blue: b)
    }

    // MARK: Drawn coins

    static let classic = CoinStyle(
        id: "classic",
        name: "Classic",
        rim: rgb(0.72, 0.53, 0.13),
        face: rgb(0.98, 0.80, 0.32),
        engraving: rgb(0.36, 0.24, 0.02),
        heads: .letter("H"),
        tails: .letter("T")
    )

    static let quarter = CoinStyle(
        id: "quarter",
        name: "Quarter",
        rim: rgb(0.42, 0.47, 0.55),
        face: rgb(0.82, 0.87, 0.93),
        engraving: rgb(0.18, 0.22, 0.28),
        heads: .symbol("crown.fill"),
        tails: .symbol("bird.fill")
    )

    static let doubloon = CoinStyle(
        id: "doubloon",
        name: "Doubloon",
        rim: rgb(0.55, 0.40, 0.10),
        face: rgb(0.85, 0.68, 0.24),
        engraving: rgb(0.25, 0.17, 0.02),
        heads: .symbol("sailboat.fill"),
        tails: .symbol("shield.fill")
    )

    static let bitcoin = CoinStyle(
        id: "bitcoin",
        name: "Bitcoin",
        rim: rgb(0.75, 0.42, 0.06),
        face: rgb(0.97, 0.62, 0.14),
        engraving: rgb(1.00, 0.98, 0.94),
        heads: .symbol("bitcoinsign"),
        tails: .symbol("globe.americas.fill")
    )

    static let jade = CoinStyle(
        id: "jade",
        name: "Jade",
        rim: rgb(0.11, 0.38, 0.31),
        face: rgb(0.34, 0.70, 0.57),
        engraving: rgb(0.04, 0.20, 0.16),
        heads: .symbol("leaf.fill"),
        tails: .symbol("sparkles")
    )

    // MARK: Real coins

    static let usCent = CoinStyle(
        id: "us-cent",
        name: "US Cent",
        rim: rgb(0.55, 0.30, 0.18),
        face: rgb(0.86, 0.57, 0.42),
        engraving: rgb(0.30, 0.14, 0.06),
        heads: .photo("us-cent-heads"),
        tails: .photo("us-cent-tails")
    )

    static let rupee = CoinStyle(
        id: "rupee",
        name: "Rupee",
        rim: rgb(0.45, 0.48, 0.53),
        face: rgb(0.84, 0.87, 0.90),
        engraving: rgb(0.20, 0.23, 0.27),
        heads: .photo("rupee-heads"),
        tails: .photo("rupee-tails")
    )

    static let fivePounds = CoinStyle(
        id: "five-pounds",
        name: "Five Pounds",
        rim: rgb(0.47, 0.36, 0.10),
        face: rgb(0.83, 0.67, 0.27),
        engraving: rgb(0.24, 0.17, 0.03),
        heads: .photo("five-pounds-heads"),
        tails: .photo("five-pounds-tails")
    )

    /// Every coin on offer — real currency first, then the drawn ones.
    static let all: [CoinStyle] = [
        rupee, usCent, fivePounds,
        classic, quarter, doubloon, bitcoin, jade,
    ]

    /// Real coins keyed by the ISO 3166-1 alpha-2 region that spends them.
    static let byRegion: [String: CoinStyle] = [
        "US": usCent,
        "IN": rupee,
        "GB": fivePounds,
    ]

    /// The coin to start someone in `region` with. Regions we don't mint a
    /// coin for get the plain heads/tails coin — handing someone another
    /// country's currency would be a stranger default than a generic one.
    static func `default`(for region: String?) -> CoinStyle {
        guard let region, let coin = byRegion[region.uppercased()] else { return classic }
        return coin
    }

    /// The starting coin for whoever is holding the watch.
    static var regionalDefault: CoinStyle {
        `default`(for: Locale.current.region?.identifier)
    }

    /// Looks a coin up by its stored identifier, falling back to the coin for
    /// the current region.
    static func named(_ id: String?) -> CoinStyle {
        all.first { $0.id == id } ?? regionalDefault
    }
}
