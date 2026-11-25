import CoreGraphics
import Testing
@testable import Batuta

@Suite struct SharedLineResizeTests {
    let area = CGRect(x: 0, y: 0, width: 1000, height: 500)
    let left: CGWindowID = 1, topRight: CGWindowID = 2, bottomRight: CGWindowID = 3, right: CGWindowID = 4

    var sideBySide: [CGWindowID: CGRect] {
        [left: CGRect(x: 0, y: 0, width: 494, height: 500), right: CGRect(x: 506, y: 0, width: 494, height: 500)]
    }

    var bspOfThree: [CGWindowID: CGRect] {
        [
            left: CGRect(x: 0, y: 0, width: 494, height: 500),
            topRight: CGRect(x: 506, y: 0, width: 494, height: 244),
            bottomRight: CGRect(x: 506, y: 256, width: 494, height: 244),
        ]
    }

    @Test func growingTheLeftWindowMovesTheLineRightAndShrinksItsNeighbour() {
        var frames = sideBySide
        let result = SharedLineResize.moveSharedLine(of: left, axis: .horizontal, by: 50, in: &frames, area: area)
        #expect(result == .moved)
        #expect(frames[left] == CGRect(x: 0, y: 0, width: 544, height: 500))
        #expect(frames[right] == CGRect(x: 556, y: 0, width: 444, height: 500))
    }

    @Test func growingTheRightWindowMovesTheNearLineLeft() {
        var frames = sideBySide
        let result = SharedLineResize.moveSharedLine(of: right, axis: .horizontal, by: 50, in: &frames, area: area)
        #expect(result == .moved)
        #expect(frames[right] == CGRect(x: 456, y: 0, width: 544, height: 500))
        #expect(frames[left] == CGRect(x: 0, y: 0, width: 444, height: 500))
    }

    @Test func shrinkingGivesTheSpaceToTheNeighbour() {
        var frames = sideBySide
        _ = SharedLineResize.moveSharedLine(of: left, axis: .horizontal, by: -50, in: &frames, area: area)
        #expect(frames[left] == CGRect(x: 0, y: 0, width: 444, height: 500))
        #expect(frames[right] == CGRect(x: 456, y: 0, width: 544, height: 500))
    }

    @Test func aMoveThatWouldMakeATileTooSmallIsBlockedAndChangesNothing() {
        var frames = sideBySide
        let result = SharedLineResize.moveSharedLine(of: left, axis: .horizontal, by: 400, in: &frames, area: area)
        #expect(result == .blockedBySmallestTile)
        #expect(frames == sideBySide)
    }

    @Test func noNeighbourOnThatAxisChangesNothing() {
        var frames = sideBySide
        let result = SharedLineResize.moveSharedLine(of: left, axis: .vertical, by: 30, in: &frames, area: area)
        #expect(result == .noNeighbour)
        #expect(frames == sideBySide)
    }

    @Test func anUnknownWindowHasNoNeighbour() {
        var frames = sideBySide
        #expect(SharedLineResize.moveSharedLine(of: 99, axis: .horizontal, by: 30, in: &frames, area: area) == .noNeighbour)
    }

    @Test func growingTheBigBspTileShrinksBothTilesAcrossTheLine() {
        var frames = bspOfThree
        _ = SharedLineResize.moveSharedLine(of: left, axis: .horizontal, by: 50, in: &frames, area: area)
        #expect(frames[left] == CGRect(x: 0, y: 0, width: 544, height: 500))
        #expect(frames[topRight] == CGRect(x: 556, y: 0, width: 444, height: 244))
        #expect(frames[bottomRight] == CGRect(x: 556, y: 256, width: 444, height: 244))
    }

    @Test func growingAStackedTileVerticallyLeavesTheSideTileAlone() {
        var frames = bspOfThree
        let result = SharedLineResize.moveSharedLine(of: topRight, axis: .vertical, by: 30, in: &frames, area: area)
        #expect(result == .moved)
        #expect(frames[topRight] == CGRect(x: 506, y: 0, width: 494, height: 274))
        #expect(frames[bottomRight] == CGRect(x: 506, y: 286, width: 494, height: 214))
        #expect(frames[left] == bspOfThree[left])
    }

    @Test func growingASmallBspTileSidewaysAlsoMovesItsStackedSibling() {
        var frames = bspOfThree
        _ = SharedLineResize.moveSharedLine(of: topRight, axis: .horizontal, by: 50, in: &frames, area: area)
        #expect(frames[topRight] == CGRect(x: 456, y: 0, width: 544, height: 244))
        #expect(frames[bottomRight] == CGRect(x: 456, y: 256, width: 544, height: 244))
        #expect(frames[left] == CGRect(x: 0, y: 0, width: 444, height: 500))
    }
}
