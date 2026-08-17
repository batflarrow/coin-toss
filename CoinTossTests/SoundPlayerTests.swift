import AVFoundation
import Testing
@testable import CoinToss

@Suite("SoundPlayer")
struct SoundPlayerTests {

    @Test("Every effect is bundled with the app", arguments: SoundPlayer.Effect.allCases)
    func effectIsBundled(effect: SoundPlayer.Effect) {
        let url = Bundle.main.url(
            forResource: effect.rawValue,
            withExtension: SoundPlayer.fileExtension
        )
        #expect(url != nil, "\(effect.rawValue).\(SoundPlayer.fileExtension) is missing from the app bundle")
    }

    @Test("Every effect decodes into a player", arguments: SoundPlayer.Effect.allCases)
    func effectDecodes(effect: SoundPlayer.Effect) throws {
        let player = try #require(
            SoundPlayer.loadPlayer(for: effect),
            "\(effect.rawValue) could not be decoded"
        )

        #expect(player.duration > 0.1, "\(effect.rawValue) is suspiciously short")
        #expect(player.duration < 3.0, "\(effect.rawValue) is too long for a tap response")
    }

    @Test("The toss finishes before the coin lands")
    func tossClearsTheLanding() throws {
        let toss = try #require(SoundPlayer.loadPlayer(for: .toss))

        // The toss is the coin leaving the hand; it must be out of the way
        // before the landing plays, or the two effects talk over each other.
        #expect(toss.duration < FlipMotion.flightDuration)
    }

    @Test("The landing outlasts the settle animation")
    func landingCoversTheBounce() throws {
        let land = try #require(SoundPlayer.loadPlayer(for: .land))

        #expect(land.duration >= FlipMotion.bounceDuration)
    }

    @Test("Preparing twice is harmless")
    func prepareIsIdempotent() {
        SoundPlayer.shared.prepare()
        SoundPlayer.shared.prepare()
    }
}
