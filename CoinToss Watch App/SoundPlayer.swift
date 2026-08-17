import AVFoundation

/// Plays the bundled coin effects through the watch speaker.
///
/// The effects are trimmed from public-domain recordings of real coins (see
/// CREDITS.md) rather than synthesised, because a synthesised coin gives itself
/// away immediately.
///
/// Uses the `ambient` audio session category so a toss never interrupts music
/// or a podcast, and stays silent when the watch is muted. Players are cached
/// and pre-rolled, because allocating one at tap time is audible as a delay.
final class SoundPlayer {
    static let shared = SoundPlayer()

    /// Names of the bundled effects, without extension.
    enum Effect: String, CaseIterable {
        /// Coins chinking together as the toss leaves the hand.
        case toss = "coin-toss"
        /// The coin striking a hard floor and bouncing to rest.
        case land = "coin-land"
    }

    static let fileExtension = "wav"

    private var players: [Effect: AVAudioPlayer] = [:]
    private var sessionConfigured = false

    private init() {}

    /// Loads and pre-rolls every effect. Safe to call more than once.
    func prepare() {
        configureSessionIfNeeded()
        for effect in Effect.allCases where players[effect] == nil {
            players[effect] = Self.loadPlayer(for: effect)
        }
    }

    func play(_ effect: Effect) {
        configureSessionIfNeeded()

        guard let player = players[effect] ?? Self.loadPlayer(for: effect) else { return }
        players[effect] = player

        // Restart from the top if the previous toss is still ringing out.
        player.currentTime = 0
        player.play()
    }

    func stop(_ effect: Effect) {
        players[effect]?.stop()
    }

    /// Builds a player for an effect, or `nil` if the resource is missing or
    /// unreadable. Exposed for tests, which assert every effect can be loaded.
    static func loadPlayer(for effect: Effect) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: effect.rawValue, withExtension: fileExtension),
              let player = try? AVAudioPlayer(contentsOf: url)
        else { return nil }

        player.prepareToPlay()
        return player
    }

    private func configureSessionIfNeeded() {
        guard !sessionConfigured else { return }
        sessionConfigured = true

        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
    }
}
