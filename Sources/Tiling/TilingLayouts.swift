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

    /// Placeholder until the real Messy rules exist: big windows pinned to the corners of a triangle-ish spread, overlapping.
    static func messyOverlap(_ windowCount: Int) -> [UnitRect] {
        guard windowCount > 1 else {
            return windowCount == 1 ? [UnitRect(x: 0.08, y: 0.04, width: 0.84, height: 0.92)] : []
        }
        let anchors: [(x: Double, y: Double)] = [(0, 0), (1, 1), (1, 0), (0, 1), (0.5, 0.5)]
        let width = windowCount == 2 ? 0.66 : 0.58
        let height = windowCount == 2 ? 0.86 : 0.66
        return (0..<windowCount).map { index in
            let anchor = anchors[index % anchors.count]
            return UnitRect(x: anchor.x * (1 - width), y: anchor.y * (1 - height), width: width, height: height)
        }
    }

    private static func customLayout(_ windowCount: Int, from layouts: [String: [UnitRect]]) -> [UnitRect]? {
        guard let rects = layouts[customLayoutKey(windowCount)], rects.count == windowCount else { return nil }
        return rects
    }
}
