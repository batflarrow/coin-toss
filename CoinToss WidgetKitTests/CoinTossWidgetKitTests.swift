import Foundation
import Testing
@testable import CoinTossWidgetKit

/// The widget's own logic, tested in isolation from both the app and the
/// extension's SwiftUI views — none of this needs a rendering environment
/// or a live widget host, just the shared store and the App Intent.
///
/// `.serialized` because every case here reads and writes the one real
/// App Group `UserDefaults` suite; run in parallel (swift-testing's
/// default) they stomp each other's state.
@Suite("CoinTossWidgetKit", .serialized)
struct CoinTossWidgetKitTests {

    @Test("The shared store round-trips a flip result")
    func lastResultRoundTrips() {
        // FlipCoinIntent itself lives in the extension target, not here —
        // it can't be moved into this framework without breaking the
        // widget's App Intents metadata (see the comment on FlipCoinIntent
        // for what that cost). This tests the store it writes through.
        SharedCoinStore.lastResult = "heads"
        #expect(SharedCoinStore.lastResult == "heads")
        SharedCoinStore.lastResult = "tails"
        #expect(SharedCoinStore.lastResult == "tails")
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

    @Test("recordFlip accumulates counts, history and last result")
    func recordFlipAccumulates() {
        SharedCoinStore.resetTally()

        SharedCoinStore.recordFlip("heads")
        SharedCoinStore.recordFlip("tails")
        SharedCoinStore.recordFlip("heads")

        #expect(SharedCoinStore.headsCount == 2)
        #expect(SharedCoinStore.tailsCount == 1)
        #expect(SharedCoinStore.lastResult == "heads")
        #expect(Array(SharedCoinStore.history.prefix(3)) == ["heads", "tails", "heads"])
    }

    @Test("recordFlip caps history at the shared limit")
    func recordFlipCapsHistory() {
        SharedCoinStore.resetTally()

        for _ in 0..<(SharedCoinStore.historyLimit + 6) {
            SharedCoinStore.recordFlip("heads")
        }

        #expect(SharedCoinStore.history.count == SharedCoinStore.historyLimit)
    }

    @Test("resetTally clears counts, history and last result")
    func resetTallyClears() {
        SharedCoinStore.recordFlip("tails")

        SharedCoinStore.resetTally()

        #expect(SharedCoinStore.headsCount == 0)
        #expect(SharedCoinStore.tailsCount == 0)
        #expect(SharedCoinStore.history.isEmpty)
        #expect(SharedCoinStore.lastResult == nil)
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
