import CoreGraphics
import Testing
@testable import Batuta

@MainActor
@Suite struct LayoutGeometryTests {
    let placementArea = CGRect(x: 54, y: 31, width: 1380, height: 820)

    @Test(arguments: TilingLayouts.evenGrid(5) + TilingLayouts.binarySpacePartition(4))
    func unitRectToFrameAndBackGivesTheSameRect(rect: UnitRect) {
        let frame = StageLayout.frame(of: rect, in: placementArea)
        #expect(isNearlyEqual(StageLayout.unitRect(of: frame, in: placementArea), rect))
    }

    @Test func frameLeavesHalfAGapOnEverySide() {
        let frame = StageLayout.frame(of: UnitRect(x: 0, y: 0, width: 1, height: 1), in: placementArea)
        #expect(frame == placementArea.insetBy(dx: 6, dy: 6))
    }

    @Test func rectsWithinFourPercentCountAsTheSame() {
        let layout = UnitRect(x: 0.1, y: 0.05, width: 0.8, height: 0.9)
        let nearby = UnitRect(x: 0.139, y: 0.011, width: 0.8, height: 0.9)
        #expect(AppSizes.isNearlySame(nearby, layout))
    }

    @Test func anEdgeMoreThanFourPercentAwayIsNotTheSame() {
        let layout = UnitRect(x: 0.1, y: 0.05, width: 0.8, height: 0.9)
        let widerToTheRight = UnitRect(x: 0.1, y: 0.05, width: 0.841, height: 0.9)
        #expect(!AppSizes.isNearlySame(widerToTheRight, layout))
    }

    @Test func onePlusOrMinusPressIsJustOutsideTheToleranceSoItIsSaved() {
        let layout = UnitRect(x: 0.1, y: 0.05, width: 0.8, height: 0.9)
        let onePress = 1.0 / 24
        let grownOnce = UnitRect(x: layout.x - onePress, y: layout.y, width: layout.width + 2 * onePress, height: layout.height)
        #expect(!AppSizes.isNearlySame(grownOnce, layout), "1/24 is just over 4%, so one press is a saved size")
    }

    @Test func nothingToCompareWithIsNotTheSame() {
        #expect(!AppSizes.isNearlySame(UnitRect(x: 0, y: 0, width: 1, height: 1), nil))
    }
}
