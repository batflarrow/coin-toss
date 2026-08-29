import Foundation

/// The things the widget/complication and the app agree on through the
/// shared App Group container: the running tally, the face of the most
/// recent flip, and which coin is currently in play.
///
/// Duplicated from the identically-named file in `CoinToss Watch App/`
/// rather than shared across the app/widget boundary — the app target
/// deliberately doesn't link this framework, so it keeps its own copy;
/// this one exists so the widget's own logic (this framework) and its
/// tests can both see the same shared state without depending on the app.
///
/// Keep the two copies in step by hand; `CoinTossWidgetKitTests` and
/// `CoinFlipperTests` between them cover the behaviour on each side.
public enum SharedCoinStore {
    private static let suiteName = "group.com.batflarrow.CoinToss"
    private static var defaults: UserDefaults? { UserDefaults(suiteName: suiteName) }

    private static let lastResultKey = "widget.lastResult"
    private static let headsCountKey = "widget.headsCount"
    private static let tailsCountKey = "widget.tailsCount"
    private static let historyKey = "widget.history"
    /// Matches the `@AppStorage("selectedCoinStyle")` key in ContentView.
    private static let selectedCoinStyleKey = "selectedCoinStyle"

    /// Kept in step with `CoinFlipper.historyLimit` in the app target — the
    /// widget can't see that type, so the number is repeated here.
    public static let historyLimit = 12

    /// "heads", "tails", or nil if no coin has ever been flipped.
    public static var lastResult: String? {
        get { defaults?.string(forKey: lastResultKey) }
        set { defaults?.set(newValue, forKey: lastResultKey) }
    }

    /// Running count of heads across every flip — from the app *or* the
    /// widget — since the last reset.
    public static var headsCount: Int {
        get { defaults?.integer(forKey: headsCountKey) ?? 0 }
        set { defaults?.set(newValue, forKey: headsCountKey) }
    }

    /// Running count of tails, same scope as ``headsCount``.
    public static var tailsCount: Int {
        get { defaults?.integer(forKey: tailsCountKey) ?? 0 }
        set { defaults?.set(newValue, forKey: tailsCountKey) }
    }

    /// Recent faces, most-recent-first, capped at ``historyLimit`` — enough
    /// for the app to rebuild its streak indicator after a widget toss.
    public static var history: [String] {
        get { defaults?.stringArray(forKey: historyKey) ?? [] }
        set { defaults?.set(newValue, forKey: historyKey) }
    }

    /// The coin style id currently in play, or nil before the app has ever
    /// written one (i.e. it's still on its regional default).
    public static var selectedCoinStyleID: String? {
        defaults?.string(forKey: selectedCoinStyleKey)
    }

    /// Records one flip into the shared tally: bumps the matching count,
    /// pushes the face onto the capped history, and updates ``lastResult``.
    /// This is the single place a widget-side toss becomes durable state
    /// the app will pick up on its next foreground.
    public static func recordFlip(_ face: String) {
        lastResult = face
        if face == "tails" { tailsCount += 1 } else { headsCount += 1 }

        var recent = history
        recent.insert(face, at: 0)
        if recent.count > historyLimit {
            recent.removeLast(recent.count - historyLimit)
        }
        history = recent
    }

    /// Clears the tally and history everywhere the app and widget share it.
    public static func resetTally() {
        lastResult = nil
        headsCount = 0
        tailsCount = 0
        history = []
    }
}
