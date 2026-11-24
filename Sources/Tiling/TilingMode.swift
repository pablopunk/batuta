import CoreGraphics

enum TilingMode: String, CaseIterable, Codable {
    case off
    case even
    case bsp
    case messy
    case custom

    var label: String {
        switch self {
        case .off: "Off"
        case .even: "Even"
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

extension TilingMode {
    var next: TilingMode {
        let all = Self.allCases
        return all[(all.firstIndex(of: self)! + 1) % all.count]
    }
}
