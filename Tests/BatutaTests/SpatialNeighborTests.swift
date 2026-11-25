import CoreGraphics
import Testing
@testable import Batuta

@Suite struct SpatialNeighborTests {
    let topLeft = CGRect(x: 0, y: 0, width: 100, height: 100)
    let topRight = CGRect(x: 110, y: 0, width: 100, height: 100)
    let bottomLeft = CGRect(x: 0, y: 110, width: 100, height: 100)
    let bottomRight = CGRect(x: 110, y: 110, width: 100, height: 100)
    var grid: [CGRect] { [topLeft, topRight, bottomLeft, bottomRight] }

    @Test func downFromTopLeftGoesToBottomLeft() {
        #expect(SpatialNeighbor.index(of: .down, from: topLeft, among: grid, excluding: 0) == 2)
    }

    @Test func rightFromTopLeftGoesToTopRight() {
        #expect(SpatialNeighbor.index(of: .right, from: topLeft, among: grid, excluding: 0) == 1)
    }

    @Test func leftFromBottomRightGoesToBottomLeft() {
        #expect(SpatialNeighbor.index(of: .left, from: bottomRight, among: grid, excluding: 3) == 2)
    }

    @Test func upFromBottomRightGoesToTopRight() {
        #expect(SpatialNeighbor.index(of: .up, from: bottomRight, among: grid, excluding: 3) == 1)
    }

    @Test func noWindowOnThatSideReturnsNil() {
        #expect(SpatialNeighbor.index(of: .up, from: topLeft, among: grid, excluding: 0) == nil)
        #expect(SpatialNeighbor.index(of: .left, from: topLeft, among: grid, excluding: 0) == nil)
    }

    @Test func aWindowThatLinesUpBeatsACloserDiagonalOne() {
        let current = CGRect(x: 0, y: 0, width: 100, height: 100)
        let farAligned = CGRect(x: 0, y: 500, width: 100, height: 100)
        let closeDiagonal = CGRect(x: 150, y: 120, width: 100, height: 100)
        let frames = [current, closeDiagonal, farAligned]
        #expect(SpatialNeighbor.index(of: .down, from: current, among: frames, excluding: 0) == 2)
    }

    @Test func aWindowOnlySlightlyAheadDoesNotCount() {
        let current = CGRect(x: 0, y: 0, width: 100, height: 100)
        let barelyRight = CGRect(x: 5, y: 0, width: 100, height: 100)
        #expect(SpatialNeighbor.index(of: .right, from: current, among: [current, barelyRight], excluding: 0) == nil)
    }
}
