import CoreGraphics

/// The window order each stage was last tiled in. Coming back to a stage with the same windows needs no tiling,
/// which also keeps any size the person changed by hand; when windows joined or left, the known ones keep their order.
@MainActor
enum StageOrders {
    private static var orders: [[CGWindowID]] = []

    static func remember(_ windows: [StageWindow]) {
        let ids = windows.map(\.id)
        let idSet = Set(ids)
        orders.removeAll { !idSet.isDisjoint(with: $0) }
        orders.append(ids)
    }

    static func swap(_ first: CGWindowID, _ second: CGWindowID) {
        guard let index = orders.firstIndex(where: { $0.contains(first) && $0.contains(second) }),
              let a = orders[index].firstIndex(of: first), let b = orders[index].firstIndex(of: second) else { return }
        orders[index].swapAt(a, b)
    }

    static func isTiledAlready(_ windows: [StageWindow]) -> Bool {
        let idSet = Set(windows.map(\.id))
        return orders.contains { Set($0) == idSet }
    }

    static func ordered(_ windows: [StageWindow]) -> [StageWindow] {
        let byID = Dictionary(windows.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        guard let known = orders.max(by: { overlap($0, byID) < overlap($1, byID) }), overlap(known, byID) > 0 else { return windows }
        let knownIDs = Set(known)
        return known.compactMap { byID[$0] } + windows.filter { !knownIDs.contains($0.id) }
    }

    private static func overlap(_ order: [CGWindowID], _ byID: [CGWindowID: StageWindow]) -> Int {
        order.filter { byID[$0] != nil }.count
    }
}
