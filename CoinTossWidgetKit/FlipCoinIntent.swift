import AppIntents
import WidgetKit

/// Flips a coin from the widget/complication itself — no need to open the
/// app. This is what makes the complication interactive rather than just a
/// launcher: the `Button` in the widget's entry view is backed by this
/// intent, so tapping it runs entirely on the watch face.
public struct FlipCoinIntent: AppIntent {
    public init() {}

    public static var title: LocalizedStringResource = "Flip Coin"
    public static var description = IntentDescription(
        "Tosses the coin and shows the result right on the complication."
    )

    public func perform() async throws -> some IntentResult {
        let face: CoinFace = Bool.random() ? .heads : .tails
        SharedCoinStore.lastResult = face.rawValue
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
