import CoinTossWidgetKit
import SwiftUI
import WidgetKit

/// What the complication shows: the most recent flip (or nothing, if the
/// coin has never been tossed from either the widget or the app), and
/// which coin is in play, so the art matches what's actually selected.
struct CoinEntry: TimelineEntry {
    let date: Date
    /// "heads", "tails", or nil.
    let result: String?
    let selectedCoinStyleID: String?

    var accessibilityLabel: String {
        switch result {
        case "heads": "Coin Toss, showing Heads"
        case "tails": "Coin Toss, showing Tails"
        default: "Coin Toss, not yet flipped"
        }
    }

    /// The art to show, or nil pre-flip — art only exists for a face that's
    /// actually landed.
    var art: WidgetCoinArt? {
        result.map { WidgetCoinCatalog.art(for: selectedCoinStyleID, face: $0) }
    }
}

struct CoinTossWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> CoinEntry {
        CoinEntry(date: .now, result: "heads", selectedCoinStyleID: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (CoinEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CoinEntry>) -> Void) {
        // Nothing here changes on a schedule — only a flip does, and a flip
        // reloads the timeline itself (from the intent or from the app).
        // One entry that never expires on its own.
        completion(Timeline(entries: [currentEntry()], policy: .never))
    }

    private func currentEntry() -> CoinEntry {
        CoinEntry(
            date: .now,
            result: SharedCoinStore.lastResult,
            selectedCoinStyleID: SharedCoinStore.selectedCoinStyleID
        )
    }
}

/// Just the glyph or photo for a coin's current art — no background, no
/// tap handling, so it can be reused at whatever size each widget family
/// needs.
///
/// `AnyView` here is just the usual way to return heterogeneous branch
/// types from one `View` — it is *not* what makes the photo case work.
/// The real fix, found by bisection, is the asset size: a coin photo
/// straight out of the app's own asset catalog (256×256, 60–140KB) makes
/// every reload fail with `WidgetKit.WidgetArchiver.ArchivingError Code=2
/// "(null)"`, for every widget family, even though the exact same view
/// tree renders fine with `Image(systemName:)` or with a small raster
/// image. Confirmed by shrinking just one coin's heads image to 64×64
/// (~9KB) while leaving everything else untouched: that one face started
/// reloading successfully while the still-oversized tails face kept
/// failing. There's a payload-size ceiling somewhere between chronod and
/// the widget-renderer XPC transport that the SDK doesn't document or
/// surface a useful error for — it just reports `Code=2 "(null)"`
/// regardless of cause. The widget's own copies of the coin photos
/// (`CoinToss Widget/Assets.xcassets/Coins`) are downsized to 88×88
/// (~15-19KB) accordingly; the app's full-size originals are untouched.
private struct CoinArtView: View {
    let art: WidgetCoinArt?
    var symbolPointSize: CGFloat = 16

    var body: some View {
        content
    }

    private var content: AnyView {
        switch art {
        case .letter(let letter):
            return AnyView(
                Text(letter)
                    .font(.system(size: symbolPointSize, weight: .semibold, design: .rounded))
            )
        case .symbol(let name):
            return AnyView(
                Image(systemName: name)
                    .font(.system(size: symbolPointSize))
            )
        case .photo(let name):
            return AnyView(
                Image(name)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 46, height: 46)
                    .clipShape(Circle())
            )
        case nil:
            // Pre-flip: an empty circle rather than any specific coin face.
            return AnyView(
                Image(systemName: "circle")
                    .font(.system(size: symbolPointSize))
            )
        }
    }
}

/// The watch-face complication: one button standing in for the coin.
/// Tapping it flips right there, no app launch required.
struct CoinTossCircularView: View {
    let entry: CoinEntry

    var body: some View {
        Button(intent: FlipCoinIntent()) {
            // Always the same view shape (ZStack of background + art) rather
            // than branching on `entry.art` to skip the background for
            // photos — WidgetKit's archiver on this OS/Xcode combination
            // fails to serialize a Button label whose content is an
            // `if/else` over two different view types (a bare `CoinArtView`
            // vs. a `ZStack<...>`), even though each branch archives fine on
            // its own. A photo fills the circle anyway, so the background
            // just sits fully hidden underneath it — same result, one
            // uniform type.
            ZStack {
                AccessoryWidgetBackground()
                CoinArtView(art: entry.art)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(entry.accessibilityLabel)
        .accessibilityHint("Flips the coin")
    }
}

/// The Smart Stack-friendly layout: coin art plus a label and the last
/// result, wide enough to actually read at a glance.
struct CoinTossRectangularView: View {
    let entry: CoinEntry

    var body: some View {
        Button(intent: FlipCoinIntent()) {
            HStack(spacing: 8) {
                // Same uniform-shape reasoning as CoinTossCircularView: no
                // if/else here, always background + art.
                ZStack {
                    AccessoryWidgetBackground()
                    CoinArtView(art: entry.art, symbolPointSize: 14)
                }
                .frame(width: 28, height: 28)
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text("Coin Toss")
                        .font(.headline)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(entry.accessibilityLabel)
        .accessibilityHint("Flips the coin")
    }

    private var subtitle: String {
        switch entry.result {
        case "heads": "Heads"
        case "tails": "Tails"
        default: "Tap to flip"
        }
    }
}

struct CoinTossWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CoinEntry

    var body: some View {
        switch family {
        case .accessoryRectangular:
            CoinTossRectangularView(entry: entry)
        default:
            CoinTossCircularView(entry: entry)
        }
    }
}

struct CoinTossWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: CoinTossWidgetKind.name, provider: CoinTossWidgetProvider()) { entry in
            CoinTossWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Coin Toss")
        .description("Flip a coin right from your watch face.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular])
    }
}

#Preview(as: .accessoryCircular) {
    CoinTossWidget()
} timeline: {
    CoinEntry(date: .now, result: nil, selectedCoinStyleID: nil)
    CoinEntry(date: .now, result: "heads", selectedCoinStyleID: "quarter")
    CoinEntry(date: .now, result: "tails", selectedCoinStyleID: "us-cent")
}

#Preview(as: .accessoryRectangular) {
    CoinTossWidget()
} timeline: {
    CoinEntry(date: .now, result: nil, selectedCoinStyleID: nil)
    CoinEntry(date: .now, result: "heads", selectedCoinStyleID: "rupee")
}
