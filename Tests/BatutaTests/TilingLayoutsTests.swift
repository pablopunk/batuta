import CoreGraphics
import Testing
@testable import Batuta

@Suite struct TilingLayoutsTests {
    static let tilingModes: [TilingMode] = [.even, .bsp, .messy, .custom]
    static let windowCounts = Array(1...8)

    @Test(arguments: tilingModes, windowCounts)
    func everyTilingModeReturnsOneRectPerWindowInsideTheUnitSquare(mode: TilingMode, windowCount: Int) {
        let rects = TilingLayouts.unitRects(for: windowCount, mode: mode, customLayouts: TilingLayouts.defaultCustomLayouts)
        #expect(rects.count == windowCount)
        #expect(rects.allSatisfy(isInsideUnitSquare))
    }

    @Test(arguments: 0...6)
    func offReturnsNoRects(windowCount: Int) {
        #expect(TilingLayouts.unitRects(for: windowCount, mode: .off, customLayouts: [:]).isEmpty)
    }

    @Test(arguments: [TilingMode.even, .bsp, .messy, .custom])
    func zeroWindowsGiveNoRects(mode: TilingMode) {
        #expect(TilingLayouts.unitRects(for: 0, mode: mode, customLayouts: [:]).isEmpty)
    }

    @Test func evenPutsUpToThreeWindowsInOneRow() {
        let rects = TilingLayouts.evenGrid(3)
        #expect(rects.allSatisfy { $0.y == 0 && $0.height == 1 })
        #expect(rects.map(\.x).allSatisfy { [0, 1.0 / 3, 2.0 / 3].contains($0) })
    }

    @Test func evenPutsFiveWindowsAsTwoOverThree() {
        let rects = TilingLayouts.evenGrid(5)
        #expect(rects.filter { $0.y == 0 }.count == 2)
        #expect(rects.filter { $0.y == 0.5 }.count == 3)
        #expect(rects.filter { $0.y == 0 }.allSatisfy { $0.width == 0.5 })
    }

    @Test func evenTilesCoverTheWholeSquareWithoutOverlap() {
        for windowCount in 1...9 {
            let area = TilingLayouts.evenGrid(windowCount).reduce(0) { $0 + $1.width * $1.height }
            #expect(abs(area - 1) < 1e-9, "window count \(windowCount)")
        }
    }

    @Test func bspSplitsSideBySideThenTopAndBottom() {
        let rects = TilingLayouts.binarySpacePartition(3)
        #expect(rects == [
            UnitRect(x: 0, y: 0, width: 0.5, height: 1),
            UnitRect(x: 0.5, y: 0, width: 0.5, height: 0.5),
            UnitRect(x: 0.5, y: 0.5, width: 0.5, height: 0.5),
        ])
    }

    @Test func messyWithMoreWindowsThanItsLayoutsFallsBackToEven() {
        #expect(TilingLayouts.messyOverlap(6) == TilingLayouts.evenGrid(6))
        #expect(TilingLayouts.messyOverlap(7) == TilingLayouts.evenGrid(7))
    }

    @Test func messyUsesItsOwnLayoutForFewWindows() {
        #expect(TilingLayouts.messyOverlap(2) != TilingLayouts.evenGrid(2))
    }

    @Test func customUsesTheSavedLayoutForThatWindowCount() {
        let saved = [UnitRect(x: 0, y: 0, width: 0.7, height: 1), UnitRect(x: 0.7, y: 0, width: 0.3, height: 1)]
        let rects = TilingLayouts.unitRects(for: 2, mode: .custom, customLayouts: ["2": saved])
        #expect(rects == saved)
    }

    @Test func customFallsBackToEvenWhenTheWindowCountIsMissing() {
        let rects = TilingLayouts.unitRects(for: 3, mode: .custom, customLayouts: ["2": TilingLayouts.evenGrid(2)])
        #expect(rects == TilingLayouts.evenGrid(3))
    }

    @Test func customFallsBackToEvenWhenTheSavedLayoutHasTheWrongCount() {
        let rects = TilingLayouts.unitRects(for: 3, mode: .custom, customLayouts: ["3": TilingLayouts.evenGrid(2)])
        #expect(rects == TilingLayouts.evenGrid(3))
    }

    @Test func defaultCustomLayoutsAreEvenForOneToSixWindows() {
        let layouts = TilingLayouts.defaultCustomLayouts
        #expect(Set(layouts.keys) == Set((1...6).map(String.init)))
        for count in 1...6 { #expect(layouts[String(count)] == TilingLayouts.evenGrid(count)) }
    }

    @Test func nextModeWrapsAroundToOff() {
        #expect(TilingMode.off.next == .even)
        #expect(TilingMode.custom.next == .off)
    }
}

@Suite struct UnitRectTests {
    @Test func clampingKeepsTheRectInsideTheUnitSquareWithTheMinimumSide() {
        let clamped = UnitRect(x: -0.2, y: 0.95, width: 0.05, height: 2).clampedToUnitSquare()
        #expect(clamped == UnitRect(x: 0, y: 0, width: 0.1, height: 1))
    }

    @Test func clampingMovesARectThatSticksOutBackInside() {
        let clamped = UnitRect(x: 0.8, y: 0.7, width: 0.5, height: 0.5).clampedToUnitSquare()
        #expect(isNearlyEqual(clamped, UnitRect(x: 0.5, y: 0.5, width: 0.5, height: 0.5)))
    }

    @Test func clampingLeavesARectThatFitsAsItIs() {
        let rect = UnitRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4)
        #expect(rect.clampedToUnitSquare() == rect)
    }

    @Test func placingScalesAndOffsetsIntoTheArea() {
        let placed = UnitRect(x: 0.5, y: 0.5, width: 0.5, height: 0.5).placed(in: CGRect(x: 100, y: 50, width: 1000, height: 500))
        #expect(placed == CGRect(x: 600, y: 300, width: 500, height: 250))
    }
}
