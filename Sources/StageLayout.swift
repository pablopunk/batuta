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
        StageOrders.remember(windows)
        let mode = mode(for: windows)
        guard mode != .off else { return }
        let placementArea = area.insetBy(dx: -gap / 2, dy: -gap / 2)
        let targets = zip(windows, unitRects(for: windows, mode: mode)).map { window, rect in
            (window: window, frame: frame(of: rect, in: placementArea))
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
        StageTilingModes.chosenMode(for: windows.map(\.id)) ?? defaultMode(for: windows)
    }

    /// The mode set in Settings for the screen these windows are on.
    static func defaultMode(for windows: [StageWindow]) -> TilingMode {
        ConfigStore.shared.config.tilingSettings(onBuiltInScreen: isOnBuiltInScreen(windows.first?.frame)).mode
    }

    /// Each screen has its own stage, so only windows on the same screen belong with this one.
    static func windowsOnSameScreen(as window: StageWindow, among windows: [StageWindow]) -> [StageWindow] {
        let screen = screen(containing: window.frame)
        return windows.filter { self.screen(containing: $0.frame) == screen }
    }

    static func isOnBuiltInScreen(_ frame: CGRect?) -> Bool {
        frame.flatMap { screen(containing: $0) }?.isBuiltIn ?? true
    }

    /// A lone window in Messy or Custom goes where you last left that app's lone window.
    static func unitRects(for windows: [StageWindow], mode: TilingMode) -> [UnitRect] {
        if AppSizes.modes.contains(mode), windows.count == 1, let saved = AppSizes.savedRect(for: windows[0]) { return [saved] }
        let settings = ConfigStore.shared.config.tilingSettings(onBuiltInScreen: isOnBuiltInScreen(windows.first?.frame))
        return TilingLayouts.unitRects(for: windows.count, mode: mode, customLayouts: settings.customLayouts)
    }

    /// The usable area grown by half a gap, so unit rects placed in it and shrunk by half a gap leave full gaps between tiles.
    static func placementArea(around frame: CGRect, besides strip: StageStrip?) -> CGRect? {
        usableArea(around: frame, besides: strip)?.insetBy(dx: -gap / 2, dy: -gap / 2)
    }

    static func frame(of rect: UnitRect, in placementArea: CGRect) -> CGRect {
        rect.placed(in: placementArea).insetBy(dx: gap / 2, dy: gap / 2)
    }

    static func unitRect(of frame: CGRect, in placementArea: CGRect) -> UnitRect {
        let outer = frame.insetBy(dx: -gap / 2, dy: -gap / 2)
        return UnitRect(
            x: (outer.minX - placementArea.minX) / placementArea.width,
            y: (outer.minY - placementArea.minY) / placementArea.height,
            width: outer.width / placementArea.width,
            height: outer.height / placementArea.height
        )
    }

    /// The area tiles may use around this window: its screen, minus the room for Stage Manager when that is on.
    static func usableArea(around frame: CGRect, besides strip: StageStrip?) -> CGRect? {
        guard let screen = screen(containing: frame) else { return nil }
        let settings = ConfigStore.shared.config.tilingSettings(onBuiltInScreen: screen.isBuiltIn)
        return usableArea(on: screen, leavingRoom: settings.leaveRoomForStageManager, besides: strip)
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
    /// The strip buttons are wider than the window pictures they draw, so the room left follows the pictures.
    @MainActor
    var thumbnailsFrame: CGRect {
        let itemFrames = items.map(\.frame)
        return StageWindows.thumbnailBounds(inside: itemFrames)
            ?? itemFrames.reduce(nil) { union, frame in union?.union(frame) ?? frame }
            ?? frame
    }
}

extension NSScreen {
    var isBuiltIn: Bool {
        guard let displayID = deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID else { return false }
        return CGDisplayIsBuiltin(displayID) != 0
    }
}
