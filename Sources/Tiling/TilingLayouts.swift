import Foundation

/// Pure layout math: where each window goes, as unit rects, for a number of windows.
enum TilingLayouts {
    static let customWindowCounts = 1...6

    static func unitRects(for windowCount: Int, mode: TilingMode, customLayouts: [String: [UnitRect]]) -> [UnitRect] {
        switch mode {
        case .off: []
        case .even: evenGrid(windowCount)
        case .bsp: binarySpacePartition(windowCount)
        case .messy: messyOverlap(windowCount)
        case .custom: customLayout(windowCount, from: customLayouts) ?? evenGrid(windowCount)
        }
    }

    static func customLayoutKey(_ windowCount: Int) -> String { String(windowCount) }

    static var defaultCustomLayouts: [String: [UnitRect]] {
        Dictionary(uniqueKeysWithValues: customWindowCounts.map { (customLayoutKey($0), evenGrid($0)) })
    }

    /// Rows of equal height, and equal columns inside each row. Lower rows take the extra windows (5 is 2 over 3).
    static func evenGrid(_ windowCount: Int) -> [UnitRect] {
        guard windowCount > 0 else { return [] }
        let rowCount = windowCount <= 3 ? 1 : Int((Double(windowCount) / 3).rounded(.up))
        let rowHeight = 1 / Double(rowCount)
        return (0..<rowCount).flatMap { row in
            let columnCount = windowsInRow(row, rowCount: rowCount, windowCount: windowCount)
            let columnWidth = 1 / Double(columnCount)
            return (0..<columnCount).map { column in
                UnitRect(x: Double(column) * columnWidth, y: Double(row) * rowHeight, width: columnWidth, height: rowHeight)
            }
        }
    }

    private static func windowsInRow(_ row: Int, rowCount: Int, windowCount: Int) -> Int {
        let base = windowCount / rowCount
        let rowsWithExtraWindow = windowCount % rowCount
        return row >= rowCount - rowsWithExtraWindow ? base + 1 : base
    }

    /// Dwindle: each window takes the first half of what is left, splitting side by side, then top and bottom, in turns.
    static func binarySpacePartition(_ windowCount: Int) -> [UnitRect] {
        guard windowCount > 0 else { return [] }
        var remaining = UnitRect(x: 0, y: 0, width: 1, height: 1)
        var rects: [UnitRect] = []
        for index in 0..<(windowCount - 1) {
            let splitsSideBySide = index.isMultiple(of: 2)
            let first = splitsSideBySide
                ? UnitRect(x: remaining.x, y: remaining.y, width: remaining.width / 2, height: remaining.height)
                : UnitRect(x: remaining.x, y: remaining.y, width: remaining.width, height: remaining.height / 2)
            rects.append(first)
            remaining = splitsSideBySide
                ? UnitRect(x: first.x + first.width, y: remaining.y, width: first.width, height: remaining.height)
                : UnitRect(x: remaining.x, y: first.y + first.height, width: remaining.width, height: first.height)
        }
        return rects + [remaining]
    }

    /// Hand-drawn layouts for 1 to 5 windows; tiles overlap on purpose. More windows fall back to Even.
    static func messyOverlap(_ windowCount: Int) -> [UnitRect] {
        let rects = messyLayouts[windowCount] ?? []
        return rects.count == windowCount ? rects : evenGrid(windowCount)
    }

    private static let messyLayouts: [Int: [UnitRect]] = [
        1: [UnitRect(x: 0.15, y: 0.1, width: 0.7, height: 0.75)],
        2: [UnitRect(x: 0.05, y: 0.05, width: 0.5, height: 0.8),
            UnitRect(x: 0.45, y: 0.15, width: 0.5, height: 0.8)],
        3: [UnitRect(x: 0.05, y: 0.05, width: 0.5, height: 0.7),
            UnitRect(x: 0.45, y: 0.1, width: 0.5, height: 0.7),
            UnitRect(x: 0.3, y: 0.3, width: 0.5, height: 0.7)],
        4: [UnitRect(x: 0.05, y: 0.05, width: 0.45, height: 0.5),
            UnitRect(x: 0.45, y: 0.05, width: 0.45, height: 0.5),
            UnitRect(x: 0.1, y: 0.4, width: 0.45, height: 0.5),
            UnitRect(x: 0.5, y: 0.45, width: 0.45, height: 0.5)],
        5: [UnitRect(x: 0, y: 0, width: 0.5, height: 0.5),
            UnitRect(x: 0.5, y: 0, width: 0.5, height: 0.5),
            UnitRect(x: 0, y: 0.5, width: 0.35, height: 0.5),
            UnitRect(x: 0.35, y: 0.5, width: 0.35, height: 0.5),
            UnitRect(x: 0.7, y: 0.5, width: 0.3, height: 0.5)],
    ]

    private static func customLayout(_ windowCount: Int, from layouts: [String: [UnitRect]]) -> [UnitRect]? {
        guard let rects = layouts[customLayoutKey(windowCount)], rects.count == windowCount else { return nil }
        return rects
    }
}
