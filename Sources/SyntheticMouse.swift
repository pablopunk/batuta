import AppKit
import CoreGraphics

/// Stage Manager ignores its Accessibility actions, so some gestures are replayed as real mouse input.
/// Points use the top-left global coordinates of Accessibility and CoreGraphics. The cursor goes back where it was.
@MainActor
enum SyntheticMouse {
    private static let stepDelay: TimeInterval = 0.012
    private static let dragSteps = 12
    private static let pressHoldDelay: TimeInterval = 0.08

    static func click(at point: CGPoint) {
        let original = currentCursorPosition
        post(.leftMouseDown, at: point)
        post(.leftMouseUp, at: point)
        CGWarpMouseCursorPosition(original)
    }

    static func drag(from start: CGPoint, to end: CGPoint, completion: @escaping @MainActor () -> Void) {
        let original = currentCursorPosition
        post(.leftMouseDown, at: start)

        var delay = pressHoldDelay
        for step in 1...dragSteps {
            let progress = CGFloat(step) / CGFloat(dragSteps)
            let point = CGPoint(x: start.x + (end.x - start.x) * progress, y: start.y + (end.y - start.y) * progress)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { post(.leftMouseDragged, at: point) }
            delay += stepDelay
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + delay + pressHoldDelay) {
            post(.leftMouseUp, at: end)
            CGWarpMouseCursorPosition(original)
            completion()
        }
    }

    private static var currentCursorPosition: CGPoint {
        CGEvent(source: nil)?.location ?? .zero
    }

    private static func post(_ type: CGEventType, at point: CGPoint) {
        guard let event = CGEvent(mouseEventSource: nil, mouseType: type, mouseCursorPosition: point, mouseButton: .left) else { return }
        event.flags = []
        event.post(tap: .cghidEventTap)
    }
}
