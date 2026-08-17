import Testing
@testable import CoinToss

@Suite("FlipMotion")
struct FlipMotionTests {

    @Test("A resting coin is flat, grounded and unscaled")
    func restingIsNeutral() {
        #expect(FlipMotion.resting.rotation == 0)
        #expect(FlipMotion.resting.lift == 0)
        #expect(FlipMotion.resting.scale == 1)
    }

    @Test("Flight and settle add up to the total duration")
    func durationsAddUp() {
        #expect(FlipMotion.totalDuration == FlipMotion.flightDuration + FlipMotion.bounceDuration)
    }

    @Test("The toss is quick enough to stay responsive")
    func flightIsSnappy() {
        // Long enough to read as a throw, short enough not to feel sluggish.
        #expect(FlipMotion.flightDuration > 0.4)
        #expect(FlipMotion.totalDuration < 1.5)
    }

    @Test("The coin settles before the result is revealed")
    func bounceFollowsFlight() {
        #expect(FlipMotion.bounceDuration > 0)
        #expect(FlipMotion.bounceDuration < FlipMotion.flightDuration)
    }
}
