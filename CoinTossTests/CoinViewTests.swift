import Testing
@testable import CoinToss

/// `CoinView` is a plain SwiftUI view struct, so its computed properties can
/// be evaluated directly, without a rendering environment — the same way
/// `CoinFlipper`'s logic is tested regardless of the UI on top of it.
@Suite("CoinView")
struct CoinViewTests {

    @Test("Every coin previews its heads face before the first flip", arguments: CoinStyle.all)
    func idleShowsHeadsArt(style: CoinStyle) {
        let view = CoinView(style: style, face: nil)
        #expect(view.currentArt == style.heads)
    }

    @Test("A landed coin shows the face it landed on", arguments: [CoinFace.heads, .tails])
    func landedShowsResultArt(face: CoinFace) {
        let view = CoinView(style: .quarter, face: face)
        #expect(view.currentArt == CoinStyle.quarter.art(for: face))
    }

    @Test("currentArt resolves to photo art regardless of flight state")
    func flippingDoesNotChangeCurrentArt() {
        // us-cent is photographic on both faces. The mid-flight fallback to a
        // drawn disc lives in `content`'s `!isFlipping` check, not here — if
        // that regresses into `currentArt` itself, this catches it.
        let view = CoinView(style: .usCent, face: .heads, isFlipping: true)
        guard case .photo = view.currentArt else {
            Issue.record("us-cent heads should still resolve to photo art mid-flight")
            return
        }
    }
}
