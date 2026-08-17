import SwiftUI

/// The coin itself: a metallic disc that tumbles about its horizontal axis.
///
/// `motion` carries the whole flight — tumble, height and the perspective
/// growth as the coin nears the viewer. Mid-flight the face is hidden, which
/// is what lets the new result be swapped in unseen. Photographic coins fall
/// back to a blank drawn disc while airborne, so they still read as a coin.
struct CoinView: View {
    let style: CoinStyle
    let face: CoinFace?
    var motion: FlipMotion = .resting
    var isFlipping: Bool = false
    var diameter: CGFloat = 88

    /// Before the first flip there is no face to show, so the coin is blank.
    private var currentArt: CoinArt? {
        face.map(style.art(for:))
    }

    var body: some View {
        content
            .frame(width: diameter, height: diameter)
            // The shadow stays on the ground, so it softens as the coin rises.
            .shadow(
                color: .black.opacity(0.5 - motion.lift * 0.008),
                radius: 3 + motion.lift * 0.30,
                y: 3 + motion.lift * 0.45
            )
            .scaleEffect(motion.scale)
            .rotation3DEffect(.degrees(motion.rotation), axis: (x: 1, y: 0, z: 0), perspective: 0.6)
            .offset(y: -motion.lift)
            .accessibilityElement()
            .accessibilityLabel(accessibilityText)
    }

    @ViewBuilder
    private var content: some View {
        if case .photo(let asset) = currentArt, !isFlipping {
            Image(asset)
                .resizable()
                .scaledToFit()
                .clipShape(Circle())
                .overlay(
                    Circle().strokeBorder(style.rim.opacity(0.45), lineWidth: 1)
                )
                .transition(.opacity)
        } else {
            drawnDisc
        }
    }

    private var drawnDisc: some View {
        ZStack {
            Circle()
                .fill(
                    AngularGradient(
                        colors: [style.rim, style.face, style.rim, style.face, style.rim],
                        center: .center
                    )
                )

            Circle()
                .inset(by: diameter * 0.055)
                .fill(
                    LinearGradient(
                        colors: [style.face, style.rim.opacity(0.75)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .inset(by: diameter * 0.055)
                .strokeBorder(style.engraving.opacity(0.25), lineWidth: 1)

            engravingView
                .foregroundStyle(style.engraving)
                .opacity(isFlipping ? 0 : 1)
        }
    }

    @ViewBuilder
    private var engravingView: some View {
        switch currentArt {
        case .letter(let text):
            Text(text)
                .font(.system(size: diameter * 0.48, weight: .heavy, design: .serif))
        case .symbol(let name):
            Image(systemName: name)
                .font(.system(size: diameter * 0.38, weight: .semibold))
        case .photo, .none:
            EmptyView()
        }
    }

    private var accessibilityText: String {
        if isFlipping { return "Coin is flipping" }
        guard let face else { return "\(style.name) coin, not yet flipped" }
        return "\(style.name) coin showing \(face.label)"
    }
}

#Preview("Every coin") {
    ScrollView {
        VStack(spacing: 8) {
            ForEach(CoinStyle.all) { style in
                HStack(spacing: 8) {
                    CoinView(style: style, face: .heads, diameter: 48)
                    CoinView(style: style, face: .tails, diameter: 48)
                }
            }
        }
    }
}
