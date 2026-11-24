import AppKit
import os

private let timingLog = Logger(subsystem: "com.pablopunk.batuta", category: "timing")

/// Places the windows of the stage with the chosen tiling mode, in the given order.
@MainActor
enum StageLayout {
    private static let gap: CGFloat = 12
    private static let fallbackStripWidth: CGFloat = 260
    static var onArranged: (() -> Void)?

    static func arrange(_ windows: [StageWindow], besides strip: StageStrip?) {
        guard let screen = windows.first.flatMap({ screen(containing: $0.frame) }) else { return }
        let config = ConfigStore.shared.config
        let settings = config.tilingSettings(onBuiltInScreen: screen.isBuiltIn)
        let area = usableArea(on: screen, leavingRoom: settings.leaveRoomForStageManager, besides: strip)
        let rects = TilingLayouts.unitRects(for: windows.count, mode: mode(for: windows), customLayouts: config.customLayouts)
        let areaIncludingHalfGaps = area.insetBy(dx: -gap / 2, dy: -gap / 2)
        let targets = zip(windows, rects).map { window, rect in
            (window: window, frame: rect.placed(in: areaIncludingHalfGaps).insetBy(dx: gap / 2, dy: gap / 2))
        }
        let started = CACurrentMediaTime()
        WindowAnimator.shared.animate(targets) {
            timingLog.notice("layout: landed after \(CACurrentMediaTime() - started, format: .fixed(precision: 3))s")
            refitWindowsThatRefusedToShrink(targets)
            onArranged?()
        }
    }

    private static func refitWindowsThatRefusedToShrink(_ targets: [(window: StageWindow, frame: CGRect)]) {
        let landed = targets.map { $0.window.element.frame ?? $0.frame }
        guard let refitted = MinimumWidthRefit.refit(targets: targets.map(\.frame), landed: landed, gap: gap) else { return }
        timingLog.notice("layout: refitting windows that refused to shrink")
        WindowAnimator.shared.animate(zip(targets, refitted).map { (window: $0.window, frame: $1) })
    }

    /// The mode the stage switched to with the shortcut, or else the one set for its screen.
    static func mode(for windows: [StageWindow]) -> TilingMode {
        if let chosen = StageTilingModes.chosenMode(for: windows.map(\.id)) { return chosen }
        let isBuiltIn = windows.first.flatMap { screen(containing: $0.frame) }?.isBuiltIn ?? true
        return ConfigStore.shared.config.tilingSettings(onBuiltInScreen: isBuiltIn).mode
    }

    private static func screen(containing frame: CGRect) -> NSScreen? {
        let appKitFrame = frame.convertedToAppKit
        return NSScreen.screens.first { $0.frame.intersects(appKitFrame) } ?? NSScreen.main
    }

    /// The screen's visible frame, in top-left coordinates, minus the side where Stage Manager lives when room is left for it.
    private static func usableArea(on screen: NSScreen, leavingRoom: Bool, besides strip: StageStrip?) -> CGRect {
        let visible = screen.visibleFrame.convertedFromAppKit.insetBy(dx: gap, dy: gap)
        guard leavingRoom else { return visible }
        let stripWidth = strip.map { $0.thumbnailsFrame.maxX - visible.minX + gap } ?? fallbackStripWidth

        if strip?.isOnLeftEdge ?? true {
            return CGRect(x: visible.minX + stripWidth, y: visible.minY, width: visible.width - stripWidth, height: visible.height)
        }
        let rightStripWidth = strip.map { visible.maxX - $0.thumbnailsFrame.minX + gap } ?? fallbackStripWidth
        return CGRect(x: visible.minX, y: visible.minY, width: visible.width - rightStripWidth, height: visible.height)
    }
}

private extension StageStrip {
    /// The strip element spans much wider than the thumbnails it shows, so the room left for it follows the thumbnails.
    var thumbnailsFrame: CGRect {
        items.map(\.frame).reduce(nil) { union, frame in union?.union(frame) ?? frame } ?? frame
    }
}

extension NSScreen {
    var isBuiltIn: Bool {
        guard let displayID = deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID else { return false }
        return CGDisplayIsBuiltin(displayID) != 0
    }
}
