import CoreGraphics

enum TilingMode: String, CaseIterable, Codable {
    case bsp
    case messy
    case custom

    var label: String {
        switch self {
        case .bsp: "BSP"
        case .messy: "Messy"
        case .custom: "Custom"
        }
    }
}

/// A rectangle in a 0...1 space with a top-left origin, so it scales to any screen area.
struct UnitRect: Codable, Equatable, Hashable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double

    static let minimumSide = 0.1

    func placed(in area: CGRect) -> CGRect {
        CGRect(
            x: area.minX + x * area.width,
            y: area.minY + y * area.height,
            width: width * area.width,
            height: height * area.height
        )
    }

    func clampedToUnitSquare() -> UnitRect {
        let clampedWidth = min(max(width, Self.minimumSide), 1)
        let clampedHeight = min(max(height, Self.minimumSide), 1)
        return UnitRect(
            x: min(max(x, 0), 1 - clampedWidth),
            y: min(max(y, 0), 1 - clampedHeight),
            width: clampedWidth,
            height: clampedHeight
        )
    }
}
