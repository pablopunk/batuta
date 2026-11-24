import Foundation

/// Pure layout math: where each window goes, as unit rects, for a number of windows.
enum TilingLayouts {
    static let customWindowCounts = 1...5

    static func unitRects(for windowCount: Int, mode: TilingMode, customLayouts: [String: [UnitRect]]) -> [UnitRect] {
        switch mode {
        case .bsp: binarySpacePartition(windowCount)
        case .messy: messyOverlap(windowCount)
        case .custom: customLayout(windowCount, from: customLayouts) ?? binarySpacePartition(windowCount)
        }
    }

    static func customLayoutKey(_ windowCount: Int) -> String { String(windowCount) }

    static var defaultCustomLayouts: [String: [UnitRect]] {
        Dictionary(uniqueKeysWithValues: customWindowCounts.map { (customLayoutKey($0), binarySpacePartition($0)) })
    }

    /// Dwindle: each window takes the first half of what is left, splitting side by side, then top and bottom, in turns.
    static func binarySpacePartition(_ windowCount: Int) -> [UnitRect] {
        guard windowCount > 0 else { return [] }
        var remaining = UnitRect(x: 0, y: 0, width: 1, height: 1)
        var rects: [UnitRect] = []
        for index in 0..<windowCount {
            if index == windowCount - 1 {
                rects.append(remaining)
                break
            }
            let splitsSideBySide = index.isMultiple(of: 2)
            if splitsSideBySide {
                let half = remaining.width / 2
                rects.append(UnitRect(x: remaining.x, y: remaining.y, width: half, height: remaining.height))
                remaining = UnitRect(x: remaining.x + half, y: remaining.y, width: half, height: remaining.height)
            } else {
                let half = remaining.height / 2
                rects.append(UnitRect(x: remaining.x, y: remaining.y, width: remaining.width, height: half))
                remaining = UnitRect(x: remaining.x, y: remaining.y + half, width: remaining.width, height: half)
            }
        }
        return rects
    }

    /// Hand-drawn layouts for 1 to 5 windows; tiles overlap on purpose. More windows fall back to BSP.
    static func messyOverlap(_ windowCount: Int) -> [UnitRect] {
        let rects = messyLayouts[windowCount] ?? []
        return rects.count == windowCount ? rects : binarySpacePartition(windowCount)
    }

    private static let messyLayouts: [Int: [UnitRect]] = [
        1: [UnitRect(x: 0.25, y: 0.15, width: 0.55, height: 0.7)],
        2: [UnitRect(x: 0.1, y: 0.1, width: 0.45, height: 0.75),
            UnitRect(x: 0.5, y: 0.15, width: 0.45, height: 0.75)],
        3: [UnitRect(x: 0.1, y: 0.05, width: 0.4, height: 0.7),
            UnitRect(x: 0.45, y: 0, width: 0.45, height: 0.7),
            UnitRect(x: 0.35, y: 0.3, width: 0.45, height: 0.65)],
        4: [UnitRect(x: 0, y: 0, width: 0.5, height: 0.5),
            UnitRect(x: 0.5, y: 0, width: 0.5, height: 0.5),
            UnitRect(x: 0, y: 0.5, width: 0.5, height: 0.5),
            UnitRect(x: 0.5, y: 0.5, width: 0.5, height: 0.5)],
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
