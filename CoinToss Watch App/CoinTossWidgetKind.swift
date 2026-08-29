/// The widget kind string, shared between the app (which reloads the
/// widget's timeline after a flip) and the widget extension itself (which
/// registers under this kind). Kept as one named constant, duplicated in
/// both targets like `SharedCoinStore`, so the two can't drift out of sync
/// with a typo in either string literal.
enum CoinTossWidgetKind {
    static let name = "CoinTossWidget"
}
