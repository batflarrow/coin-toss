import Foundation

/// The things the widget/complication and the app agree on through the
/// shared App Group container: the face of the most recent flip, and which
/// coin is currently in play.
///
/// Deliberately duplicated from the identically-named file in
/// `CoinToss Watch App/` rather than shared via a framework or
/// synchronized-group membership: it's small, and this project's
/// container/watch-app split already keeps targets independent on purpose.
enum SharedCoinStore {
    private static let suiteName = "group.com.batflarrow.CoinToss"
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
