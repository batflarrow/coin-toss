import SwiftUI
import WidgetKit

/// What the complication shows: the most recent flip, or nothing if the
/// coin has never been tossed from either the widget or the app.
struct CoinEntry: TimelineEntry {
    let date: Date
    /// "heads", "tails", or nil.
    let result: String?
}

struct CoinTossWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> CoinEntry {
        CoinEntry(date: .now, result: "heads")
    }

    func getSnapshot(in context: Context, completion: @escaping (CoinEntry) -> Void) {
        completion(CoinEntry(date: .now, result: SharedCoinStore.lastResult))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CoinEntry>) -> Void) {
        let entry = CoinEntry(date: .now, result: SharedCoinStore.lastResult)
        // Nothing here changes on a schedule — only a flip does, and a flip
        // reloads the timeline itself (from the intent or from the app).
        // One entry that never expires on its own.
        completion(Timeline(entries: [entry], policy: .never))
    }
}

/// The complication face: a single button standing in for the coin. Tapping
/// it flips right there, no app launch required.
struct CoinTossWidgetEntryView: View {
    var entry: CoinEntry

    var body: some View {
        Button(intent: FlipCoinIntent()) {
            ZStack {
                AccessoryWidgetBackground()
                if let result = entry.result {
                    Text(result == "heads" ? "H" : "T")
                        .font(.system(.title2, design: .serif, weight: .heavy))
                } else {
                    // Never flipped from anywhere yet.
                    Image(systemName: "circle.fill")
                        .font(.system(size: 16))
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Flips the coin")
    }

    private var accessibilityLabel: String {
        switch entry.result {
        case "heads": "Coin Toss, showing Heads"
        case "tails": "Coin Toss, showing Tails"
        default: "Coin Toss, not yet flipped"
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
        .supportedFamilies([.accessoryCircular])
    }
}

#Preview(as: .accessoryCircular) {
    CoinTossWidget()
} timeline: {
    CoinEntry(date: .now, result: nil)
    CoinEntry(date: .now, result: "heads")
    CoinEntry(date: .now, result: "tails")
}
