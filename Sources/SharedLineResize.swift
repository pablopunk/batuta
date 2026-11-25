import CoreGraphics

/// Moves the line the focused window shares with its neighbours, so the focused window changes by an amount and the
/// windows across the line absorb it. Pure frame math, so it can run without Accessibility.
enum SharedLineResize {
    static let gap: CGFloat = 12
    private static let edgeTolerance: CGFloat = 20
    static let smallestTileShare: CGFloat = 1 / 6

    enum Axis { case horizontal, vertical }
    enum LineMove { case moved, blockedBySmallestTile, noNeighbour }

    /// Picks the line on the far side (right or bottom) when a neighbour is there, else the near side.
    static func moveSharedLine(of focusedID: CGWindowID, axis: Axis, by amount: CGFloat, in frames: inout [CGWindowID: CGRect], area: CGRect) -> LineMove {
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
}

private extension SharedLineResize.Axis {
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
