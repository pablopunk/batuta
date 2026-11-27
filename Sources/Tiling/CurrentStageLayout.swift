import AppKit

/// Where the windows of an open stage sit now, as unit rects in tiling order, so a custom layout can copy them.
@MainActor
enum CurrentStageLayout {
    static func unitRects(ofStageWith windowCount: Int, onScreensWhere usesTheseSettings: (_ isBuiltIn: Bool) -> Bool) -> [UnitRect]? {
        let stage = stagesByScreen()
            .filter { screen, _ in usesTheseSettings(screen.isBuiltIn) }
            .map { _, windows in StageOrders.ordered(windows) }
            .first { $0.count == windowCount }
        guard let stage, let first = stage.first,
              let placementArea = StageLayout.placementArea(around: first.frame, besides: StageStrip.closest(to: first.frame)) else { return nil }
        return stage.map { StageLayout.unitRect(of: $0.frame, in: placementArea).clampedToUnitSquare() }
    }

    private static func stagesByScreen() -> [NSScreen: [StageWindow]] {
        let windows = StageWindows.visibleSortedLeftToRight().tileable
        return Dictionary(grouping: windows.compactMap { window in StageLayout.screen(containing: window.frame).map { ($0, window) } }, by: \.0)
            .mapValues { $0.map(\.1) }
    }
}
