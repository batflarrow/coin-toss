/// The widget kind string, shared between the app (which reloads the
/// widget's timeline after a flip) and the widget extension itself (which
/// registers under this kind). Duplicated from the identically-named file
/// in `CoinToss Watch App/` so the two can't drift out of sync with a typo
/// in either string literal — the app target deliberately doesn't link
/// this framework, same reasoning as everything else duplicated between
/// the app and the widget side.
public enum CoinTossWidgetKind {
    public static let name = "CoinTossWidget"
}
