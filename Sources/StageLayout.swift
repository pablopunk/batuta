import AppKit

/// Rough first layout: every window of the stage gets an equal column, in the given order.
@MainActor
enum StageLayout {
    private static let gap: CGFloat = 12
    private static let fallbackStripWidth: CGFloat = 260

    static func arrangeInColumns(_ windows: [StageWindow], besides strip: StageStrip?) {
        guard !windows.isEmpty, let area = usableArea(near: windows[0].frame, besides: strip) else { return }
        let count = CGFloat(windows.count)
        let columnWidth = (area.width - gap * (count - 1)) / count

        let targets = windows.enumerated().map { index, window in
            (window: window, frame: CGRect(
                x: area.minX + CGFloat(index) * (columnWidth + gap),
                y: area.minY,
                width: columnWidth,
                height: area.height
            ))
        }
        WindowAnimator.shared.animate(targets)
    }

    /// The screen's visible frame, in top-left coordinates, minus the side where the Stage Manager strip lives.
    private static func usableArea(near frame: CGRect, besides strip: StageStrip?) -> CGRect? {
        let appKitFrame = frame.convertedToAppKit
        guard let screen = NSScreen.screens.first(where: { $0.frame.intersects(appKitFrame) }) ?? NSScreen.main else { return nil }
        let visible = screen.visibleFrame.convertedFromAppKit.insetBy(dx: gap, dy: gap)
        let stripWidth = strip.map { $0.frame.maxX - visible.minX + gap } ?? fallbackStripWidth

        if strip?.isOnLeftEdge ?? true {
            return CGRect(x: visible.minX + stripWidth, y: visible.minY, width: visible.width - stripWidth, height: visible.height)
        }
        let rightStripWidth = strip.map { visible.maxX - $0.frame.minX + gap } ?? fallbackStripWidth
        return CGRect(x: visible.minX, y: visible.minY, width: visible.width - rightStripWidth, height: visible.height)
    }
}
