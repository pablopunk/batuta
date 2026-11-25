import CoreGraphics
@testable import Batuta

let unitSquareTolerance = 1e-9

func isInsideUnitSquare(_ rect: UnitRect) -> Bool {
    rect.x >= -unitSquareTolerance && rect.y >= -unitSquareTolerance
        && rect.width > 0 && rect.height > 0
        && rect.x + rect.width <= 1 + unitSquareTolerance && rect.y + rect.height <= 1 + unitSquareTolerance
}

func isNearlyEqual(_ a: UnitRect, _ b: UnitRect, tolerance: Double = 1e-9) -> Bool {
    abs(a.x - b.x) <= tolerance && abs(a.y - b.y) <= tolerance
        && abs(a.width - b.width) <= tolerance && abs(a.height - b.height) <= tolerance
}
