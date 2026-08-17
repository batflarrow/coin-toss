import SwiftUI

/// The coin's position in flight, driven by ``FlipMotion/keyframes(turns:)``.
struct FlipMotion: Equatable, Sendable {
    /// Degrees of tumble about the coin's horizontal axis.
    var rotation = 0.0
    /// Points above the resting position.
    var lift = 0.0
    /// Grows as the coin nears the viewer, and squashes on impact.
    var scale = 1.0

    static let resting = FlipMotion()
}

extension FlipMotion {
    /// Seconds from launch to the coin touching down. The result is revealed here.
    static let flightDuration = 0.70
    /// Seconds of settling after touchdown.
    static let bounceDuration = 0.20

    static var totalDuration: Double { flightDuration + bounceDuration }

    private static let apex = 20.0
    private static let riseDuration = 0.34
    private static let fallDuration = flightDuration - riseDuration

    /// A coin thrown upward decelerates to a stop, then falls back faster and
    /// faster. Matching the start and end velocities to that arc is what makes
    /// the toss read as thrown rather than merely animated.
    @KeyframeTrackContentBuilder<Double>
    private static func liftTrack() -> some KeyframeTrackContent<Double> {
        // Launch: fast off the thumb, coasting to a stop at the top.
        CubicKeyframe(apex, duration: riseDuration, startVelocity: 2 * apex / riseDuration, endVelocity: 0)
        // Fall: from rest, gathering speed all the way down.
        CubicKeyframe(0, duration: fallDuration, startVelocity: 0, endVelocity: -2 * apex / fallDuration)
        // A short hop off the surface, then rest.
        CubicKeyframe(apex * 0.22, duration: bounceDuration * 0.45)
        CubicKeyframe(0, duration: bounceDuration * 0.55)
    }

    @KeyframeTrackContentBuilder<Double>
    private static func scaleTrack() -> some KeyframeTrackContent<Double> {
        CubicKeyframe(1.14, duration: riseDuration)
        CubicKeyframe(1.0, duration: fallDuration)
        CubicKeyframe(0.93, duration: bounceDuration * 0.3)   // squash on impact
        CubicKeyframe(1.0, duration: bounceDuration * 0.7)
    }

    /// Tumbles at a near-constant rate through the flight, then decelerates
    /// into a whole number of turns so the coin lands face-on.
    @KeyframeTrackContentBuilder<Double>
    private static func rotationTrack(turns: Double) -> some KeyframeTrackContent<Double> {
        let total = turns * 360
        LinearKeyframe(total * 0.78, duration: flightDuration * 0.68)
        CubicKeyframe(total, duration: flightDuration * 0.32)
        LinearKeyframe(total, duration: bounceDuration)       // held while it settles
    }

    @KeyframesBuilder<FlipMotion>
    static func keyframes(turns: Double) -> some Keyframes<FlipMotion> {
        KeyframeTrack(\.lift) { liftTrack() }
        KeyframeTrack(\.scale) { scaleTrack() }
        KeyframeTrack(\.rotation) { rotationTrack(turns: turns) }
    }
}
