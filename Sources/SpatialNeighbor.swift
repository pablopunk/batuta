import CoreGraphics

/// Finds the window next to another one in a direction, so focus and swaps follow what is on screen,
/// not only the left-to-right order. Windows that line up with the current one win over closer diagonal ones.
enum SpatialNeighbor {
    private static let minimumStep: CGFloat = 8

    static func index(of direction: Direction, from current: CGRect, among frames: [CGRect], excluding currentIndex: Int) -> Int? {
        frames.indices
            .filter { $0 != currentIndex && isAhead(frames[$0], of: current, toward: direction) }
            .min { score(frames[$0], from: current, toward: direction) < score(frames[$1], from: current, toward: direction) }
    }

    private static func isAhead(_ candidate: CGRect, of current: CGRect, toward direction: Direction) -> Bool {
        switch direction {
        case .left: candidate.midX < current.midX - minimumStep
        case .right: candidate.midX > current.midX + minimumStep
        case .up: candidate.midY < current.midY - minimumStep
        case .down: candidate.midY > current.midY + minimumStep
        }
    }

    private static func score(_ candidate: CGRect, from current: CGRect, toward direction: Direction) -> (Int, CGFloat, CGFloat) {
        let isHorizontal = direction == .left || direction == .right
        let alongAxis = isHorizontal ? abs(candidate.midX - current.midX) : abs(candidate.midY - current.midY)
        let acrossAxis = isHorizontal ? abs(candidate.midY - current.midY) : abs(candidate.midX - current.midX)
        let linesUp = isHorizontal
            ? candidate.minY < current.maxY && candidate.maxY > current.minY
            : candidate.minX < current.maxX && candidate.maxX > current.minX
        return (linesUp ? 0 : 1, alongAxis, acrossAxis)
    }
}
