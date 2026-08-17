import Testing
import UIKit
@testable import CoinToss

@Suite("CoinStyle")
struct CoinStyleTests {

    @Test("Identifiers are unique")
    func identifiersAreUnique() {
        let ids = CoinStyle.all.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test("Names are unique and non-empty")
    func namesAreUnique() {
        let names = CoinStyle.all.map(\.name)
        #expect(Set(names).count == names.count)
        #expect(names.allSatisfy { !$0.isEmpty })
    }

    @Test("Every coin shows something different on each face")
    func facesDiffer() {
        for style in CoinStyle.all {
            #expect(style.heads != style.tails, "\(style.name) uses the same art for both faces")
        }
    }

    @Test("Art lookup matches the declared faces")
    func artLookup() {
        for style in CoinStyle.all {
            #expect(style.art(for: .heads) == style.heads)
            #expect(style.art(for: .tails) == style.tails)
        }
    }

    @Test("The regional default is one of the offered coins")
    func defaultIsOffered() {
        #expect(CoinStyle.all.contains(CoinStyle.regionalDefault))
    }

    @Test("Lookup by identifier returns the matching coin")
    func lookupByIdentifier() {
        for style in CoinStyle.all {
            #expect(CoinStyle.named(style.id) == style)
        }
    }

    @Test("Lookup falls back to the regional coin for unknown identifiers")
    func lookupFallsBack() {
        #expect(CoinStyle.named(nil) == CoinStyle.regionalDefault)
        #expect(CoinStyle.named("") == CoinStyle.regionalDefault)
        #expect(CoinStyle.named("no-such-coin") == CoinStyle.regionalDefault)
    }

    @Test(
        "Each supported region starts with its own currency",
        arguments: [("US", CoinStyle.usCent), ("IN", .rupee), ("GB", .fivePounds)]
    )
    func regionPicksLocalCurrency(region: String, expected: CoinStyle) {
        #expect(CoinStyle.default(for: region) == expected)
    }

    @Test("Region matching ignores case")
    func regionIsCaseInsensitive() {
        #expect(CoinStyle.default(for: "us") == .usCent)
        #expect(CoinStyle.default(for: "In") == .rupee)
    }

    @Test(
        "Regions without a coin fall back to plain heads and tails",
        arguments: ["JP", "FR", "BR", "ZZ", ""]
    )
    func unsupportedRegionsFallBack(region: String) {
        #expect(CoinStyle.default(for: region) == .classic)
    }

    @Test("An unknown region falls back to plain heads and tails")
    func missingRegionFallsBack() {
        #expect(CoinStyle.default(for: nil) == .classic)
    }

    @Test("Every region-mapped coin is offered in the list")
    func regionCoinsAreOffered() {
        for (region, style) in CoinStyle.byRegion {
            #expect(CoinStyle.all.contains(style), "\(region) maps to a coin that is not on offer")
        }
    }

    @Test("Region-mapped coins are real currency, not invented ones")
    func regionCoinsArePhotographic() {
        for (region, style) in CoinStyle.byRegion {
            #expect(style.isPhotographic, "\(region) maps to \(style.name), which is not a real coin")
        }
    }

    @Test("Symbol and letter art is never blank")
    func drawnArtIsPresent() {
        for style in CoinStyle.all {
            for art in [style.heads, style.tails] {
                switch art {
                case .symbol(let name):
                    #expect(!name.isEmpty, "\(style.name) has an empty symbol name")
                case .letter(let text):
                    #expect(!text.isEmpty, "\(style.name) has empty letter art")
                case .photo:
                    break
                }
            }
        }
    }

    @Test("A photographic coin uses photographs on both faces")
    func photographicCoinsAreConsistent() {
        for style in CoinStyle.all where !style.photoAssets.isEmpty {
            #expect(
                style.isPhotographic,
                "\(style.name) mixes a photograph with drawn art, which reads as a different coin per face"
            )
            #expect(style.photoAssets.count == 2)
        }
    }

    @Test("Every referenced coin photo is bundled with the app")
    func photosAreBundled() {
        for style in CoinStyle.all {
            for asset in style.photoAssets {
                #expect(
                    UIImage(named: asset) != nil,
                    "\(asset) is missing from the asset catalogue"
                )
            }
        }
    }

    @Test("Real currency is offered before the invented coins")
    func realCoinsComeFirst() {
        let firstDrawn = CoinStyle.all.firstIndex { !$0.isPhotographic }
        let lastPhoto = CoinStyle.all.lastIndex { $0.isPhotographic }

        #expect(firstDrawn != nil)
        #expect(lastPhoto != nil)
        #expect(lastPhoto! < firstDrawn!)
    }
}
