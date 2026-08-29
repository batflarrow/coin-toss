/// What a coin face shows — a minimal mirror of `CoinArt` from `CoinStyle.swift`.
public enum WidgetCoinArt: Equatable {
    case letter(String)
    case symbol(String)
    case photo(String)
}

/// A minimal mirror of the app's `CoinStyle` catalog — just which art each
/// coin shows on each face, nothing about colors or the flight animation
/// (the widget doesn't animate; `AccessoryWidgetBackground()` supplies the
/// backdrop). Duplicated from `CoinStyle.swift` rather than shared across
/// targets, same reasoning as `SharedCoinStore` — keep this in sync by hand
/// if the app's coin catalog changes. `CoinTossWidgetKitTests` asserts
/// every id `CoinStyle.all` declares has an entry here, so a forgotten
/// update fails a test instead of just quietly showing the wrong art.
public enum WidgetCoinCatalog {
    /// Every coin id this catalog knows about, in the order declared below —
    /// exposed so a test can cross-check it against `CoinStyle.all`'s ids.
    public static let knownStyleIDs: [String] = [
        "classic", "quarter", "doubloon", "bitcoin", "jade",
        "us-cent", "rupee", "five-pounds",
    ]

    private static let art: [String: (heads: WidgetCoinArt, tails: WidgetCoinArt)] = [
        "classic": (.letter("H"), .letter("T")),
        "quarter": (.symbol("crown.fill"), .symbol("bird.fill")),
        "doubloon": (.symbol("sailboat.fill"), .symbol("shield.fill")),
        "bitcoin": (.symbol("bitcoinsign"), .symbol("globe.americas.fill")),
        "jade": (.symbol("leaf.fill"), .symbol("sparkles")),
        "us-cent": (.photo("us-cent-heads"), .photo("us-cent-tails")),
        "rupee": (.photo("rupee-heads"), .photo("rupee-tails")),
        "five-pounds": (.photo("five-pounds-heads"), .photo("five-pounds-tails")),
    ]

    /// Falls back to the plain letter coin for an unrecognized or missing
    /// style id — e.g. the very first launch, before the app has ever
    /// written a selection into the shared store.
    public static func art(for styleID: String?, face: String) -> WidgetCoinArt {
        let pair = art[styleID ?? ""] ?? (.letter("H"), .letter("T"))
        return face == "tails" ? pair.tails : pair.heads
    }
}
