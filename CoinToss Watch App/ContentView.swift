import SwiftUI
import WatchKit
import WidgetKit

struct ContentView: View {
    @AppStorage("selectedCoinStyle") private var selectedStyleID = CoinStyle.regionalDefault.id
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("tallyVisible") private var tallyVisible = true

    @State private var flipper = CoinFlipper()
    @State private var isFlipping = false
    /// Bumped on each toss to retrigger the flight animation.
    @State private var flipCount = 0
    /// Whole turns for the current toss, so the coin always lands face-on.
    @State private var turns = 4.0
    @State private var flipTask: Task<Void, Never>?

    private var style: CoinStyle { CoinStyle.named(selectedStyleID) }

    var body: some View {
        ZStack {
            // Anywhere on the screen tosses — no precision tapping on the move.
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture(perform: flip)

            VStack(spacing: 8) {
                coin

                Text(headline)
                    .font(.headline)
                    .contentTransition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: headline)

                if tallyVisible && flipper.totalFlips > 0 {
                    tally
                }
            }
            .animation(.easeInOut(duration: 0.25), value: flipper.totalFlips)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SettingsView(
                        selectedStyleID: $selectedStyleID,
                        soundEnabled: $soundEnabled,
                        tallyVisible: $tallyVisible
                    )
                } label: {
                    Image(systemName: "gearshape.fill")
                }
                .accessibilityLabel("Settings")
            }
        }
        .onAppear { SoundPlayer.shared.prepare() }
        .onDisappear { flipTask?.cancel() }
    }

    /// The coin is the primary control, and the star of the screen.
    private var coin: some View {
        Button(action: flip) {
            CoinView(style: style, face: flipper.result, isFlipping: isFlipping)
                .keyframeAnimator(
                    initialValue: FlipMotion.resting,
                    trigger: flipCount
                ) { view, motion in
                    view.modifier(FlipMotionModifier(motion: motion))
                } keyframes: { _ in
                    FlipMotion.keyframes(turns: turns)
                }
        }
        .buttonStyle(.plain)
        .disabled(isFlipping)
        // The coin is the screen's one action, so it's what Double Tap
        // (Series 9/Ultra 2+) triggers — no separate gesture code needed.
        .handGestureShortcut(.primaryAction)
        .accessibilityIdentifier("coin")
        .accessibilityHint("Flips the coin")
    }

    /// Heads and tails counts as two tags, with reset tucked in beside them.
    private var tally: some View {
        HStack(spacing: 6) {
            HStack(spacing: 6) {
                TallyTag(letter: "H", count: flipper.headsCount, color: style.headsTint)
                TallyTag(letter: "T", count: flipper.tailsCount, color: style.tailsTint)
            }
            // One spoken summary beats swiping through two separate tags, and
            // it carries the streak that no longer earns screen space.
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(tallySummary)

            Button(action: reset) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(.secondary.opacity(0.18), in: Capsule())
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(isFlipping)
            .accessibilityLabel("Reset tally")
        }
    }

    private var tallySummary: String {
        var summary = "\(flipper.headsCount) heads, \(flipper.tailsCount) tails, "
            + "out of \(flipper.totalFlips) flips"
        if flipper.currentStreak > 1, let face = flipper.result {
            summary += ", \(flipper.currentStreak) \(face.label.lowercased()) in a row"
        }
        return summary
    }

    private var headline: String {
        if isFlipping { return "Flipping…" }
        return flipper.result?.label ?? "Tap to flip"
    }

    private func flip() {
        guard !isFlipping else { return }

        isFlipping = true
        turns = Double(Int.random(in: 3...5))
        flipCount += 1

        WKInterfaceDevice.current().play(.start)
        if soundEnabled { SoundPlayer.shared.play(.toss) }

        flipTask?.cancel()
        flipTask = Task {
            try? await Task.sleep(for: .seconds(FlipMotion.flightDuration))
            guard !Task.isCancelled else { return }

            // Reveal on touchdown, so the face is readable as the coin settles.
            let face = flipper.flip()
            WKInterfaceDevice.current().play(.success)
            if soundEnabled { SoundPlayer.shared.play(.land) }
            isFlipping = false

            // The widget/complication reads this through the App Group, so a
            // flip made in the app shows up there too without waiting for
            // its own timeline to refresh on its own schedule.
            SharedCoinStore.lastResult = face.rawValue
            WidgetCenter.shared.reloadTimelines(ofKind: CoinTossWidgetKind.name)
        }
    }

    private func reset() {
        flipTask?.cancel()
        isFlipping = false
        SoundPlayer.shared.stop(.toss)
        WKInterfaceDevice.current().play(.click)
        withAnimation(.easeInOut(duration: 0.25)) {
            flipper.reset()
        }
        SharedCoinStore.lastResult = nil
        WidgetCenter.shared.reloadTimelines(ofKind: CoinTossWidgetKind.name)
    }
}

/// Applies a ``FlipMotion`` sample to the coin.
private struct FlipMotionModifier: ViewModifier {
    let motion: FlipMotion

    func body(content: Content) -> some View {
        content
            .scaleEffect(motion.scale)
            .rotation3DEffect(.degrees(motion.rotation), axis: (x: 1, y: 0, z: 0), perspective: 0.6)
            .offset(y: -motion.lift)
    }
}

/// A single count, tinted to match the coin currently in play.
private struct TallyTag: View {
    let letter: String
    let count: Int
    let color: Color

    var body: some View {
        Text("\(letter) \(count)")
            .font(.caption.weight(.semibold))
            .monospacedDigit()
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.20), in: Capsule())
            .accessibilityLabel(letter == "H" ? "\(count) heads" : "\(count) tails")
    }
}

#Preview {
    NavigationStack {
        ContentView()
    }
}
