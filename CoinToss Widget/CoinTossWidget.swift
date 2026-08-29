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
private struct CoinArtView: View {
    let art: WidgetCoinArt?
    var symbolPointSize: CGFloat = 16

    var body: some View {
        switch art {
        case .letter(let text):
            Text(text)
                .font(.system(size: symbolPointSize * 1.1, weight: .heavy, design: .serif))
        case .symbol(let name):
            Image(systemName: name)
                .font(.system(size: symbolPointSize, weight: .semibold))
        case .photo(let name):
            Image(name)
                .resizable()
                .scaledToFill()
                .clipShape(Circle())
        case nil:
            // Never flipped from anywhere yet.
            Image(systemName: "circle.fill")
                .font(.system(size: symbolPointSize))
        }
    }
}

/// The watch-face complication: one button standing in for the coin.
/// Tapping it flips right there, no app launch required.
struct CoinTossCircularView: View {
    let entry: CoinEntry

    var body: some View {
        Button(intent: FlipCoinIntent()) {
            if case .photo = entry.art {
                // A photo fills the whole circle itself — layering it over
                // AccessoryWidgetBackground would just hide the background
                // entirely, so skip it for this case only.
                CoinArtView(art: entry.art)
            } else {
                ZStack {
                    AccessoryWidgetBackground()
                    CoinArtView(art: entry.art)
                }
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
                ZStack {
                    if case .photo = entry.art {
                        CoinArtView(art: entry.art)
                    } else {
                        AccessoryWidgetBackground()
                        CoinArtView(art: entry.art, symbolPointSize: 14)
                    }
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
