import Foundation
import Testing
@testable import CoinTossWidgetKit

/// The widget's own logic, tested in isolation from both the app and the
/// extension's SwiftUI views — none of this needs a rendering environment
/// or a live widget host, just the shared store and the App Intent.
@Suite("CoinTossWidgetKit")
struct CoinTossWidgetKitTests {

    @Test("Flipping records a valid result in the shared store")
    func flipRecordsAResult() async throws {
        SharedCoinStore.lastResult = nil
        _ = try await FlipCoinIntent().perform()
        #expect(SharedCoinStore.lastResult == "heads" || SharedCoinStore.lastResult == "tails")
    }

    @Test("Flipping enough times produces both faces")
    func flippingProducesBothFaces() async throws {
        var seen: Set<String> = []
        for _ in 0..<40 {
            _ = try await FlipCoinIntent().perform()
            if let result = SharedCoinStore.lastResult {
                seen.insert(result)
            }
        }
        #expect(seen == ["heads", "tails"])
    }

    @Test("Every coin the app offers has art in the widget's catalog", arguments: WidgetCoinCatalog.knownStyleIDs)
    func everyKnownCoinHasArt(styleID: String) {
        // Every id in `knownStyleIDs` must resolve to *something other than*
        // the unknown-id fallback — i.e. it's actually in the lookup table,
        // not silently falling back to the plain letter coin.
        let headsArt = WidgetCoinCatalog.art(for: styleID, face: "heads")
        let fallbackArt = WidgetCoinCatalog.art(for: "not-a-real-style-id", face: "heads")
        if styleID == "classic" {
            // classic genuinely *is* the plain letter coin, so it can't be
            // distinguished from the fallback this way — just check it's
            // the expected letter art directly.
            #expect(headsArt == .letter("H"))
        } else {
            #expect(headsArt != fallbackArt)
        }
    }

    @Test("An unrecognized or missing style id falls back to the plain letter coin")
    func unknownStyleFallsBackToLetterCoin() {
        #expect(WidgetCoinCatalog.art(for: nil, face: "heads") == .letter("H"))
        #expect(WidgetCoinCatalog.art(for: nil, face: "tails") == .letter("T"))
        #expect(WidgetCoinCatalog.art(for: "not-a-real-style-id", face: "heads") == .letter("H"))
    }

    @Test("Heads and tails art differ for every coin")
    func headsAndTailsArtDiffer() {
        for styleID in WidgetCoinCatalog.knownStyleIDs {
            let heads = WidgetCoinCatalog.art(for: styleID, face: "heads")
            let tails = WidgetCoinCatalog.art(for: styleID, face: "tails")
            #expect(heads != tails, "\(styleID) shows the same art on both faces")
        }
    }

    @Test("The shared store round-trips the selected coin style")
    func selectedStyleRoundTrips() {
        // SharedCoinStore.selectedCoinStyleID is read-only from the widget's
        // side (only the app writes it), so write through the same
        // UserDefaults suite directly to simulate the app having done so.
        UserDefaults(suiteName: "group.com.batflarrow.CoinToss")?
            .set("rupee", forKey: "selectedCoinStyle")
        #expect(SharedCoinStore.selectedCoinStyleID == "rupee")
    }

    @Test("The widget kind string is non-empty and stable")
    func widgetKindIsStable() {
        #expect(CoinTossWidgetKind.name == "CoinTossWidget")
    }
}
