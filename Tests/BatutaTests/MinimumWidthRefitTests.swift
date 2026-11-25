import CoreGraphics
import Testing
@testable import Batuta

@Suite struct MinimumWidthRefitTests {
    let gap: CGFloat = 10
    var threeInARow: [CGRect] {
        [CGRect(x: 0, y: 0, width: 300, height: 500), CGRect(x: 310, y: 0, width: 300, height: 500), CGRect(x: 620, y: 0, width: 300, height: 500)]
    }

    @Test func aWindowThatStaysWiderKeepsItsWidthAndTheOthersShareTheRest() throws {
        var landed = threeInARow
        landed[0].size.width = 400
        let refitted = try #require(MinimumWidthRefit.refit(targets: threeInARow, landed: landed, gap: gap))
        #expect(refitted == [
            CGRect(x: 0, y: 0, width: 400, height: 500),
            CGRect(x: 410, y: 0, width: 250, height: 500),
            CGRect(x: 670, y: 0, width: 250, height: 500),
        ])
        #expect(refitted.last?.maxX == threeInARow.last?.maxX)
    }

    @Test func everyWindowLandingWhereAskedNeedsNothing() {
        #expect(MinimumWidthRefit.refit(targets: threeInARow, landed: threeInARow, gap: gap) == nil)
    }

    @Test func widthsWithinTheToleranceNeedNothing() {
        var landed = threeInARow
        landed[1].size.width = 301
        #expect(MinimumWidthRefit.refit(targets: threeInARow, landed: landed, gap: gap) == nil)
    }

    @Test func differentWindowCountsNeedNothing() {
        #expect(MinimumWidthRefit.refit(targets: threeInARow, landed: Array(threeInARow.prefix(2)), gap: gap) == nil)
    }

    @Test func aLoneWindowInItsRowIsLeftAsItIs() {
        let targets = [CGRect(x: 0, y: 0, width: 300, height: 500)]
        let landed = [CGRect(x: 0, y: 0, width: 400, height: 500)]
        #expect(MinimumWidthRefit.refit(targets: targets, landed: landed, gap: gap) == nil)
    }

    @Test func onlyTheRowWithTheWideWindowChanges() throws {
        let topRow = [CGRect(x: 0, y: 0, width: 445, height: 245), CGRect(x: 455, y: 0, width: 445, height: 245)]
        let bottomRow = [CGRect(x: 0, y: 255, width: 445, height: 245), CGRect(x: 455, y: 255, width: 445, height: 245)]
        var landed = topRow + bottomRow
        landed[2].size.width = 545
        let refitted = try #require(MinimumWidthRefit.refit(targets: topRow + bottomRow, landed: landed, gap: gap))
        #expect(Array(refitted.prefix(2)) == topRow)
        #expect(refitted[2] == CGRect(x: 0, y: 255, width: 545, height: 245))
        #expect(refitted[3] == CGRect(x: 555, y: 255, width: 345, height: 245))
    }
}
