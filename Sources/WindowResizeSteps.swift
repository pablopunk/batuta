import AppKit

/// Navigate + "+" / "-" resizes the focused window by a fixed step, so every press feels the same.
/// In Even and BSP stages it moves the lines the window shares with its neighbours, which give or take the same
/// space, so tiles never overlap. Elsewhere, or with no neighbour, it grows or shrinks around its center.
@MainActor
enum WindowResizeSteps {
    private static let stepsAcrossArea: CGFloat = 12
    private static let gap: CGFloat = 12
    private static let edgeTolerance: CGFloat = 20
    private static let smallestTileShare: CGFloat = 1 / 6

    static func grow() { resize(grows: true) }
    static func shrink() { resize(grows: false) }

    private static func resize(grows: Bool) {
        let windows = StageWindows.visibleSortedLeftToRight().map { window in
            StageWindow(element: window.element, pid: window.pid, id: window.id, frame: WindowAnimator.shared.frameIncludingAnimation(of: window))
        }
        guard let focusedID = StageWindows.focusedWindowID(),
              let focused = windows.first(where: { $0.id == focusedID }),
              let area = StageLayout.usableArea(around: focused.frame, besides: StageStrip.closest(to: focused.frame)) else { return }
        let step = CGSize(width: area.width / stepsAcrossArea, height: area.height / stepsAcrossArea)
        let sign: CGFloat = grows ? 1 : -1

        let mode = StageLayout.mode(for: windows)
        if mode == .even || mode == .bsp {
            var frames = Dictionary(uniqueKeysWithValues: windows.map { ($0.id, $0.frame) })
            let sideways = moveSharedLine(of: focused.id, axis: .horizontal, by: sign * step.width, in: &frames, area: area)
            let upDown = moveSharedLine(of: focused.id, axis: .vertical, by: sign * step.height, in: &frames, area: area)
            if sideways != .noNeighbour || upDown != .noNeighbour {
                let targets = windows.compactMap { window in frames[window.id].flatMap { $0 == window.frame ? nil : (window: window, frame: $0) } }
                if !targets.isEmpty { WindowAnimator.shared.animate(targets) }
                return
            }
        }
        resizeAroundCenter(focused, by: CGSize(width: sign * step.width, height: sign * step.height), within: area)
    }

    fileprivate enum Axis { case horizontal, vertical }
    private enum LineMove { case moved, blockedBySmallestTile, noNeighbour }

    /// Picks the line on the far side (right or bottom) when a neighbour is there, else the near side,
    /// and moves it so the focused window changes by `amount` and the windows across the line absorb it.
    private static func moveSharedLine(of focusedID: CGWindowID, axis: Axis, by amount: CGFloat, in frames: inout [CGWindowID: CGRect], area: CGRect) -> LineMove {
        guard let focused = frames[focusedID] else { return .noNeighbour }
        for farSide in [true, false] {
            let line = axis.line(of: focused, farSide: farSide, gap: gap)
            let across = frames.filter { $0.key != focusedID && touches($0.value, line: line, axis: axis, fromFarSide: farSide) && axis.overlapsAcross($0.value, focused) }
            guard !across.isEmpty else { continue }
            let sameSide = frames.filter { entry in
                touches(entry.value, line: line, axis: axis, fromFarSide: !farSide) && across.values.contains { axis.overlapsAcross($0, entry.value) }
            }
            let shift = farSide ? amount : -amount
            var moved = frames
            for id in sameSide.keys { moved[id] = axis.movingEdge(of: moved[id]!, farSide: farSide, by: shift) }
            for id in across.keys { moved[id] = axis.movingEdge(of: moved[id]!, farSide: !farSide, by: shift) }
            let smallest = axis.length(of: area) * smallestTileShare
            guard (Array(sameSide.keys) + Array(across.keys)).allSatisfy({ axis.length(of: moved[$0]!) >= smallest }) else { return .blockedBySmallestTile }
            frames = moved
            return .moved
        }
        return .noNeighbour
    }

    private static func touches(_ frame: CGRect, line: CGFloat, axis: Axis, fromFarSide: Bool) -> Bool {
        let edge = fromFarSide ? axis.min(of: frame) - gap : axis.max(of: frame)
        return abs(edge - line) < edgeTolerance
    }

    private static func resizeAroundCenter(_ window: StageWindow, by delta: CGSize, within area: CGRect) {
        let frame = window.frame
        let width = min(max(frame.width + delta.width, area.width * smallestTileShare), area.width)
        let height = min(max(frame.height + delta.height, area.height * smallestTileShare), area.height)
        var resized = CGRect(x: frame.midX - width / 2, y: frame.midY - height / 2, width: width, height: height)
        resized.origin.x = min(max(resized.minX, area.minX), area.maxX - width)
        resized.origin.y = min(max(resized.minY, area.minY), area.maxY - height)
        guard resized.integral != frame else { return }
        WindowAnimator.shared.animate([(window, resized.integral)], afterLanding: AppSizes.rememberLoneMessyWindowIfMoved)
    }
}

private extension WindowResizeSteps.Axis {
    func min(of rect: CGRect) -> CGFloat { self == .horizontal ? rect.minX : rect.minY }
    func max(of rect: CGRect) -> CGFloat { self == .horizontal ? rect.maxX : rect.maxY }
    func length(of rect: CGRect) -> CGFloat { self == .horizontal ? rect.width : rect.height }

    /// The line between the focused window and its neighbour, on the focused window's edge.
    func line(of rect: CGRect, farSide: Bool, gap: CGFloat) -> CGFloat {
        farSide ? max(of: rect) : min(of: rect) - gap
    }

    func overlapsAcross(_ a: CGRect, _ b: CGRect) -> Bool {
        self == .horizontal ? a.minY < b.maxY && a.maxY > b.minY : a.minX < b.maxX && a.maxX > b.minX
    }

    func movingEdge(of rect: CGRect, farSide: Bool, by shift: CGFloat) -> CGRect {
        switch (self, farSide) {
        case (.horizontal, true): CGRect(x: rect.minX, y: rect.minY, width: rect.width + shift, height: rect.height)
        case (.horizontal, false): CGRect(x: rect.minX + shift, y: rect.minY, width: rect.width - shift, height: rect.height)
        case (.vertical, true): CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height + shift)
        case (.vertical, false): CGRect(x: rect.minX, y: rect.minY + shift, width: rect.width, height: rect.height - shift)
        }
    }
}
