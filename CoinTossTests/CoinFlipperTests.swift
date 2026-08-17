import Testing
@testable import CoinToss

/// Feeds `CoinFlipper` a scripted, repeating sequence of faces so the tests
/// never depend on real randomness.
private final class ScriptedCoin {
    private let faces: [CoinFace]
    private var index = 0

    init(_ faces: [CoinFace]) {
        precondition(!faces.isEmpty)
        self.faces = faces
    }

    func next() -> CoinFace {
        defer { index += 1 }
        return faces[index % faces.count]
    }
}

private func flipper(scripted faces: [CoinFace]) -> CoinFlipper {
    let script = ScriptedCoin(faces)
    return CoinFlipper(randomize: script.next)
}

@Suite("CoinFlipper")
struct CoinFlipperTests {

    @Test("Starts with no result and empty tallies")
    func initialState() {
        let coin = flipper(scripted: [.heads])

        #expect(coin.result == nil)
        #expect(coin.headsCount == 0)
        #expect(coin.tailsCount == 0)
        #expect(coin.totalFlips == 0)
        #expect(coin.history.isEmpty)
        #expect(coin.currentStreak == 0)
        #expect(coin.headsShare == 0)
    }

    @Test("A flip returns the face and publishes it as the result")
    func flipPublishesResult() {
        let coin = flipper(scripted: [.tails])

        let face = coin.flip()

        #expect(face == .tails)
        #expect(coin.result == .tails)
    }

    @Test("Each face increments only its own tally", arguments: [CoinFace.heads, .tails])
    func tallyIncrementsForFace(face: CoinFace) {
        let coin = flipper(scripted: [face])

        coin.flip()

        #expect(coin.headsCount == (face == .heads ? 1 : 0))
        #expect(coin.tailsCount == (face == .tails ? 1 : 0))
        #expect(coin.totalFlips == 1)
    }

    @Test("Tallies accumulate across a mixed sequence")
    func tallyAccumulates() {
        let coin = flipper(scripted: [.heads, .heads, .tails])

        for _ in 0..<6 { coin.flip() }

        #expect(coin.headsCount == 4)
        #expect(coin.tailsCount == 2)
        #expect(coin.totalFlips == 6)
    }

    @Test("History records newest first")
    func historyIsNewestFirst() {
        let coin = flipper(scripted: [.heads, .tails, .tails])

        coin.flip()
        coin.flip()
        coin.flip()

        #expect(coin.history == [.tails, .tails, .heads])
    }

    @Test("History is capped at the history limit")
    func historyIsCapped() {
        let coin = flipper(scripted: [.heads])

        for _ in 0..<(CoinFlipper.historyLimit + 25) { coin.flip() }

        #expect(coin.history.count == CoinFlipper.historyLimit)
        #expect(coin.totalFlips == CoinFlipper.historyLimit + 25)
    }

    @Test("Streak counts consecutive matching faces")
    func streakCountsRepeats() {
        let coin = flipper(scripted: [.tails, .heads, .heads, .heads])

        coin.flip() // tails
        #expect(coin.currentStreak == 1)

        coin.flip() // heads
        #expect(coin.currentStreak == 1)

        coin.flip() // heads
        #expect(coin.currentStreak == 2)

        coin.flip() // heads
        #expect(coin.currentStreak == 3)
    }

    @Test("Streak never exceeds the retained history")
    func streakBoundedByHistory() {
        let coin = flipper(scripted: [.heads])

        for _ in 0..<(CoinFlipper.historyLimit + 10) { coin.flip() }

        #expect(coin.currentStreak == CoinFlipper.historyLimit)
    }

    @Test("Heads share reflects the proportion of heads")
    func headsShareIsProportional() {
        let coin = flipper(scripted: [.heads, .tails, .tails, .tails])

        for _ in 0..<4 { coin.flip() }

        #expect(coin.headsShare == 0.25)
    }

    @Test("Reset clears every piece of state")
    func resetClearsState() {
        let coin = flipper(scripted: [.heads, .tails])

        for _ in 0..<5 { coin.flip() }
        coin.reset()

        #expect(coin.result == nil)
        #expect(coin.headsCount == 0)
        #expect(coin.tailsCount == 0)
        #expect(coin.totalFlips == 0)
        #expect(coin.history.isEmpty)
        #expect(coin.currentStreak == 0)
        #expect(coin.headsShare == 0)
    }

    @Test("Flipping works again after a reset")
    func flipAfterReset() {
        let coin = flipper(scripted: [.heads])

        coin.flip()
        coin.reset()
        coin.flip()

        #expect(coin.totalFlips == 1)
        #expect(coin.headsCount == 1)
        #expect(coin.result == .heads)
    }

    @Test("The default randomizer produces both faces")
    func defaultRandomizerIsNotStuck() {
        let coin = CoinFlipper()

        for _ in 0..<1_000 { coin.flip() }

        // The chance of a fair coin missing a face in 1,000 flips is ~2^-999.
        #expect(coin.headsCount > 0)
        #expect(coin.tailsCount > 0)
        #expect(coin.totalFlips == 1_000)
    }
}

@Suite("CoinFace")
struct CoinFaceTests {

    @Test("There are exactly two faces")
    func hasTwoCases() {
        #expect(CoinFace.allCases.count == 2)
    }

    @Test("Labels and symbols are distinct and stable")
    func labelsAndSymbols() {
        #expect(CoinFace.heads.label == "Heads")
        #expect(CoinFace.tails.label == "Tails")
        #expect(CoinFace.heads.symbol == "H")
        #expect(CoinFace.tails.symbol == "T")
    }
}
