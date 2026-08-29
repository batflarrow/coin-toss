/// The widget kind string, shared between the app (which reloads the
/// widget's timeline after a flip) and the widget extension itself (which
/// registers under this kind). Duplicated from the identically-named file
/// in `CoinToss Watch App/` so the two can't drift out of sync with a typo
/// in either string literal.
enum CoinTossWidgetKind {
    static let name = "CoinTossWidget"
}
