import CoreGraphics

/// Some apps refuse to get narrower than their minimum width. After the first layout lands, windows in the same row
/// that stayed wider keep their real width and the others share what is left, so nothing overlaps or leaves the screen.
enum MinimumWidthRefit {
    private static let tolerance: CGFloat = 2

    static func refit(targets: [CGRect], landed: [CGRect], gap: CGFloat) -> [CGRect]? {
        guard targets.count == landed.count else { return nil }
        var refitted = targets
        for row in rowsOfIndices(targets) where row.count > 1 {
            let widths = sharedWidths(row: row, targets: targets, landed: landed, gap: gap)
            var x = targets[row[0]].minX
            for (index, width) in zip(row, widths) {
                refitted[index] = CGRect(x: x, y: targets[index].minY, width: width, height: targets[index].height)
                x += width + gap
            }
        }
        return refitted == targets ? nil : refitted
    }

    private static func rowsOfIndices(_ targets: [CGRect]) -> [[Int]] {
        let rowKey = { (rect: CGRect) in "\(Int(rect.minY.rounded()))-\(Int(rect.height.rounded()))" }
        let grouped = Dictionary(grouping: targets.indices, by: { rowKey(targets[$0]) })
        return grouped.values.map { $0.sorted { targets[$0].minX < targets[$1].minX } }
    }

    private static func sharedWidths(row: [Int], targets: [CGRect], landed: [CGRect], gap: CGFloat) -> [CGFloat] {
        let rowWidth = targets[row.last!].maxX - targets[row[0]].minX - gap * CGFloat(row.count - 1)
        var refusesToShrink = Set(row.filter { landed[$0].width > targets[$0].width + tolerance })
        while true {
            let fixedWidth = refusesToShrink.reduce(0) { $0 + landed[$1].width }
            let flexibleCount = row.count - refusesToShrink.count
            guard flexibleCount > 0 else { return row.map { landed[$0].width } }
            let share = (rowWidth - fixedWidth) / CGFloat(flexibleCount)
            let newlyTooNarrow = row.filter { !refusesToShrink.contains($0) && landed[$0].width > share + tolerance && landed[$0].width > targets[$0].width + tolerance }
            guard newlyTooNarrow.isEmpty else {
                refusesToShrink.formUnion(newlyTooNarrow)
                continue
            }
            return row.map { refusesToShrink.contains($0) ? landed[$0].width : share }
        }
    }
}
