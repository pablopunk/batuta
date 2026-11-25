import ApplicationServices
import CoreGraphics
import Testing
@testable import Batuta

/// StageOrders keeps global state, so every test uses its own window IDs.
@MainActor
@Suite struct StageOrdersTests {
    private func windows(_ ids: [CGWindowID]) -> [StageWindow] {
        ids.map { StageWindow(element: AXUIElementCreateApplication(getpid()), pid: getpid(), id: $0, frame: .zero) }
    }

    @Test func aStageWithTheSameWindowsInAnyOrderIsTiledAlready() {
        StageOrders.remember(windows([2001, 2002, 2003]))
        #expect(StageOrders.isTiledAlready(windows([2003, 2001, 2002])))
    }

    @Test func aStageWithAWindowMoreOrLessIsNotTiledAlready() {
        StageOrders.remember(windows([2101, 2102]))
        #expect(!StageOrders.isTiledAlready(windows([2101, 2102, 2103])))
        #expect(!StageOrders.isTiledAlready(windows([2101])))
    }

    @Test func knownWindowsKeepTheirOrderAndNewOnesGoLast() {
        StageOrders.remember(windows([2201, 2202, 2203]))
        let ordered = StageOrders.ordered(windows([2203, 2204, 2201, 2202]))
        #expect(ordered.map(\.id) == [2201, 2202, 2203, 2204])
    }

    @Test func windowsThatLeftAreSkipped() {
        StageOrders.remember(windows([2301, 2302, 2303]))
        #expect(StageOrders.ordered(windows([2303, 2301])).map(\.id) == [2301, 2303])
    }

    @Test func unknownWindowsKeepTheGivenOrder() {
        #expect(StageOrders.ordered(windows([2402, 2401])).map(\.id) == [2402, 2401])
    }

    @Test func swappingChangesTheRememberedOrder() {
        StageOrders.remember(windows([2501, 2502, 2503]))
        StageOrders.swap(2501, 2503)
        #expect(StageOrders.ordered(windows([2501, 2502, 2503])).map(\.id) == [2503, 2502, 2501])
    }

    @Test func rememberingAStageForgetsOrdersThatShareAWindow() {
        StageOrders.remember(windows([2601, 2602]))
        StageOrders.remember(windows([2602, 2603]))
        #expect(!StageOrders.isTiledAlready(windows([2601, 2602])))
        #expect(StageOrders.isTiledAlready(windows([2602, 2603])))
    }
}
