import Foundation

/// The things the widget/complication and the app agree on through the
/// shared App Group container: the face of the most recent flip, and which
/// coin is currently in play.
///
/// The app's own on-screen tally stays session-only, exactly as it always
/// has — this is a separate, persisted record that exists purely so the
/// widget can show and update a result without opening the app.
///
/// Deliberately duplicated in the widget extension target rather than
/// shared via a framework or synchronized-group membership: it's small,
/// and this project's container/watch-app split already keeps targets
/// independent on purpose (see `CoinToss/` vs `CoinToss Watch App/`).
enum SharedCoinStore {
    /// Internal rather than private so `ContentView` can point its
    /// `selectedCoinStyle` @AppStorage at the same suite — the widget can
    /// only see the coin the user picked if it's saved here rather than in
    /// the default (per-app, non-shared) UserDefaults domain.
    static let suiteName = "group.com.batflarrow.CoinToss"
    private static var defaults: UserDefaults? { UserDefaults(suiteName: suiteName) }

    private static let lastResultKey = "widget.lastResult"
    /// Matches the `@AppStorage("selectedCoinStyle")` key in ContentView.
    private static let selectedCoinStyleKey = "selectedCoinStyle"

    /// "heads", "tails", or nil if no coin has ever been flipped.
    static var lastResult: String? {
        get { defaults?.string(forKey: lastResultKey) }
        set { defaults?.set(newValue, forKey: lastResultKey) }
    }

    /// The coin style id currently in play, or nil before the app has ever
    /// written one (i.e. it's still on its regional default).
    static var selectedCoinStyleID: String? {
        defaults?.string(forKey: selectedCoinStyleKey)
    }
}
