import Foundation

/// The one thing the widget/complication and the app agree on through the
/// shared App Group container: the face of the most recent flip.
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
    private static let suiteName = "group.com.batflarrow.CoinToss"
    private static var defaults: UserDefaults? { UserDefaults(suiteName: suiteName) }
    private static let lastResultKey = "widget.lastResult"

    /// "heads", "tails", or nil if no coin has ever been flipped.
    static var lastResult: String? {
        get { defaults?.string(forKey: lastResultKey) }
        set { defaults?.set(newValue, forKey: lastResultKey) }
    }
}
