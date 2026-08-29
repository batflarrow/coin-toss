import AppIntents
import CoinTossWidgetKit
import WidgetKit

/// Flips a coin from the widget/complication itself — no need to open the
/// app. This is what makes the complication interactive rather than just a
/// launcher: the `Button` in the widget's entry view is backed by this
/// intent, so tapping it runs entirely on the watch face.
///
/// Lives in the extension target itself, not in CoinTossWidgetKit, even
/// though the framework would make it unit-testable — the App Intents
/// metadata extractor only registers intents it finds in the extension's
/// *own* binary. An intent defined in a linked framework compiles and
/// links fine, but the extension's Metadata.appintents comes back empty
/// for it, and the system silently fails to host the whole widget as a
/// result (confirmed: the widget rendered solid black on every family
/// while this lived in the framework, immediately after that move, and
/// went back to normal once moved back here). Not something to re-attempt
/// without a real fix for that metadata gap.
struct FlipCoinIntent: AppIntent {
    static var title: LocalizedStringResource = "Flip Coin"
    static var description = IntentDescription(
        "Tosses the coin and shows the result right on the complication."
    )

    func perform() async throws -> some IntentResult {
        let face: CoinFace = Bool.random() ? .heads : .tails

        // A short beat before the result lands. While `perform()` is still
        // running the widget shows its `.invalidatableContent()` redacted —
        // that shimmer is the "tossing…" cue, and without a pause here it
        // flicks past too fast to register.
        try? await Task.sleep(for: .seconds(0.6))

        // Goes through the shared tally, not just `lastResult`, so a toss
        // made here counts towards the running heads/tails the app shows
        // once it next comes to the foreground.
        SharedCoinStore.recordFlip(face.rawValue)
        WidgetCenter.shared.reloadTimelines(ofKind: CoinTossWidgetKind.name)
        return .result()
    }
}

/// A minimal mirror of the app's `CoinFace` — just enough for this intent to
/// pick a face without depending on the app target. Kept private to this
/// file; `SharedCoinStore` only ever sees the raw string.
private enum CoinFace: String {
    case heads
    case tails
}
