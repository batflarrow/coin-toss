import SwiftUI

@main
struct CoinTossApp: App {
    init() {
        // The tally now lives in the shared App Group store and is seeded
        // back on launch, so UI tests — which expect a clean "out of 1
        // flips" from a fresh start — need it wiped first. Passed by
        // `CoinTossUITests.launchApp()`; a no-op in every real launch.
        if ProcessInfo.processInfo.arguments.contains("-uitest-reset-store") {
            SharedCoinStore.store(headsCount: 0, tailsCount: 0, history: [], lastResult: nil)
        }
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView()
            }
        }
    }
}
