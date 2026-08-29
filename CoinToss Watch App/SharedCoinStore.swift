import Foundation

/// The things the widget/complication and the app agree on through the
/// shared App Group container: the running tally, the face of the most
/// recent flip, and which coin is currently in play.
///
/// The app's on-screen tally is seeded from here on every foreground and
/// written back after every flip, so a toss made from the widget shows up
/// in the app and vice versa. The tally therefore also survives the app
/// being killed — a deliberate change from its old session-only life, made
/// when the widget became able to flip on its own.
///
/// Deliberately duplicated in the widget extension target (see
/// `CoinTossWidgetKit/SharedCoinStore.swift`) rather than shared via a
/// framework: it's small, and this project's container/watch-app split
/// already keeps targets independent on purpose.
enum SharedCoinStore {
    /// Internal rather than private so `ContentView` can point its
    /// `selectedCoinStyle` @AppStorage at the same suite — the widget can
    /// only see the coin the user picked if it's saved here rather than in
    /// the default (per-app, non-shared) UserDefaults domain.
    static let suiteName = "group.com.batflarrow.CoinToss"
    private static var defaults: UserDefaults? { UserDefaults(suiteName: suiteName) }

    private static let lastResultKey = "widget.lastResult"
    private static let headsCountKey = "widget.headsCount"
    private static let tailsCountKey = "widget.tailsCount"
    private static let historyKey = "widget.history"
    /// Matches the `@AppStorage("selectedCoinStyle")` key in ContentView.
    private static let selectedCoinStyleKey = "selectedCoinStyle"

    /// "heads", "tails", or nil if no coin has ever been flipped.
    static var lastResult: String? {
        get { defaults?.string(forKey: lastResultKey) }
        set { defaults?.set(newValue, forKey: lastResultKey) }
    }

    /// Running count of heads across every flip — app or widget — since the
    /// last reset.
    static var headsCount: Int {
        get { defaults?.integer(forKey: headsCountKey) ?? 0 }
        set { defaults?.set(newValue, forKey: headsCountKey) }
    }

    /// Running count of tails, same scope as ``headsCount``.
    static var tailsCount: Int {
        get { defaults?.integer(forKey: tailsCountKey) ?? 0 }
        set { defaults?.set(newValue, forKey: tailsCountKey) }
    }

    /// Recent faces, most-recent-first, capped at `CoinFlipper.historyLimit`.
    static var history: [String] {
        get { defaults?.stringArray(forKey: historyKey) ?? [] }
        set { defaults?.set(newValue, forKey: historyKey) }
    }

    /// The coin style id currently in play. Writable so the app can push its
    /// current selection here proactively — the widget shows the plain
    /// letter coin until this key exists, and `@AppStorage` doesn't persist
    /// its default value on its own.
    static var selectedCoinStyleID: String? {
        get { defaults?.string(forKey: selectedCoinStyleKey) }
        set { defaults?.set(newValue, forKey: selectedCoinStyleKey) }
    }

    /// Overwrites the shared tally with the app's current `CoinFlipper`
    /// state. Called after every in-app flip and reset so the store stays
    /// the single source of truth both sides read back.
    static func store(headsCount: Int, tailsCount: Int, history: [String], lastResult: String?) {
        self.headsCount = headsCount
        self.tailsCount = tailsCount
        self.history = history
        self.lastResult = lastResult
    }
}
