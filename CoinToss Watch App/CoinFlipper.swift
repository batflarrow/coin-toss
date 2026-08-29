import Foundation

/// One of the two faces of a coin.
enum CoinFace: String, CaseIterable, Sendable {
    case heads
    case tails

    var label: String {
        switch self {
        case .heads: "Heads"
        case .tails: "Tails"
        }
    }

    /// Single-character glyph shown on the coin itself.
    var symbol: String {
        switch self {
        case .heads: "H"
        case .tails: "T"
        }
    }
}

/// Holds the outcome of the most recent toss plus running tallies.
///
/// The randomness is injected so tests can drive a deterministic sequence of
/// faces. All state changes are synchronous — the flip *animation* is the
/// view's concern, which keeps this type trivially testable.
@Observable
final class CoinFlipper {
    /// Number of past results kept for the streak indicator.
    static let historyLimit = 12

    private(set) var result: CoinFace?
    private(set) var headsCount = 0
    private(set) var tailsCount = 0

    /// Most recent result first, capped at ``historyLimit``.
    private(set) var history: [CoinFace] = []

    private let randomize: () -> CoinFace

    init(randomize: @escaping () -> CoinFace = { CoinFace.allCases.randomElement()! }) {
        self.randomize = randomize
    }

    var totalFlips: Int { headsCount + tailsCount }

    /// Share of flips that came up heads, in `0...1`. Zero when nothing has been flipped.
    var headsShare: Double {
        totalFlips == 0 ? 0 : Double(headsCount) / Double(totalFlips)
    }

    /// How many times in a row the newest face has repeated. Zero before the first flip.
    var currentStreak: Int {
        guard let newest = history.first else { return 0 }
        return history.prefix { $0 == newest }.count
    }

    /// Tosses the coin, records the outcome, and returns it.
    @discardableResult
    func flip() -> CoinFace {
        let face = randomize()
        result = face

        switch face {
        case .heads: headsCount += 1
        case .tails: tailsCount += 1
        }

        history.insert(face, at: 0)
        if history.count > Self.historyLimit {
            history.removeLast(history.count - Self.historyLimit)
        }

        return face
    }

    /// Replaces the whole tally with a previously persisted one — used to
    /// seed the flipper from the shared App Group store on launch and on
    /// every foreground, so a toss made from the widget is reflected here.
    /// `history` is trimmed to ``historyLimit`` defensively; `result` is
    /// taken to be the newest face in that history.
    func restore(headsCount: Int, tailsCount: Int, history: [CoinFace]) {
        self.headsCount = max(0, headsCount)
        self.tailsCount = max(0, tailsCount)
        self.history = Array(history.prefix(Self.historyLimit))
        self.result = self.history.first
    }

    /// Clears the tallies and history, returning the coin to its pre-flip state.
    func reset() {
        result = nil
        headsCount = 0
        tailsCount = 0
        history.removeAll()
    }
}
