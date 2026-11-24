import AppKit

/// Places the windows of the stage with the chosen tiling mode, in the given order.
@MainActor
enum StageLayout {
    private static let gap: CGFloat = 12
    private static let fallbackStripWidth: CGFloat = 260

    static func arrange(_ windows: [StageWindow], besides strip: StageStrip?) {
        guard !windows.isEmpty, let area = usableArea(near: windows[0].frame, besides: strip) else { return }
        let config = ConfigStore.shared.config
        let rects = TilingLayouts.unitRects(for: windows.count, mode: config.tilingMode, customLayouts: config.customLayouts)
        let areaIncludingHalfGaps = area.insetBy(dx: -gap / 2, dy: -gap / 2)
        let targets = zip(windows, rects).map { window, rect in
            (window: window, frame: rect.placed(in: areaIncludingHalfGaps).insetBy(dx: gap / 2, dy: gap / 2))
        }
        WindowAnimator.shared.animate(targets)
    }

    /// The screen's visible frame, in top-left coordinates, minus the side where the Stage Manager strip lives when that setting is on.
    private static func usableArea(near frame: CGRect, besides strip: StageStrip?) -> CGRect? {
        let appKitFrame = frame.convertedToAppKit
        guard let screen = NSScreen.screens.first(where: { $0.frame.intersects(appKitFrame) }) ?? NSScreen.main else { return nil }
        let visible = screen.visibleFrame.convertedFromAppKit.insetBy(dx: gap, dy: gap)
        guard ConfigStore.shared.config.leaveRoomForStrip else { return visible }
        let stripWidth = strip.map { $0.frame.maxX - visible.minX + gap } ?? fallbackStripWidth

        if strip?.isOnLeftEdge ?? true {
            return CGRect(x: visible.minX + stripWidth, y: visible.minY, width: visible.width - stripWidth, height: visible.height)
        }
        let rightStripWidth = strip.map { visible.maxX - $0.frame.minX + gap } ?? fallbackStripWidth
        return CGRect(x: visible.minX, y: visible.minY, width: visible.width - rightStripWidth, height: visible.height)
    }
}
