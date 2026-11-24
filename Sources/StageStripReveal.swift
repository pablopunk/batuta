import AppKit

/// When windows reach the screen edge, Stage Manager hides the strip until the pointer touches that edge.
/// While picking a stage, the pointer is parked on the edge so the strip shows, then put back where it was.
@MainActor
enum StageStripReveal {
    private static var cursorBeforeReveal: CGPoint?

    static func reveal(near frame: CGRect?, onLeftEdge: Bool) {
        if cursorBeforeReveal == nil { cursorBeforeReveal = SyntheticMouse.cursorPosition }
        guard let screen = screenFrame(containing: frame) else { return }
        SyntheticMouse.move(to: CGPoint(x: onLeftEdge ? screen.minX : screen.maxX - 1, y: screen.midY))
    }

    static func putCursorBack() {
        guard let cursor = cursorBeforeReveal else { return }
        cursorBeforeReveal = nil
        SyntheticMouse.move(to: cursor)
    }

    static func forgetCursor() {
        cursorBeforeReveal = nil
    }

    private static func screenFrame(containing frame: CGRect?) -> CGRect? {
        let screen = frame.flatMap { frame in NSScreen.screens.first { $0.frame.intersects(frame.convertedToAppKit) } } ?? NSScreen.main
        return screen?.frame.convertedFromAppKit
    }
}
