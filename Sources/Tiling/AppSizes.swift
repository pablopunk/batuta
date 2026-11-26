import AppKit
import os

private let appSizesLog = Logger(subsystem: "com.pablopunk.batuta", category: "appSizes")

/// Remembers where you put an app's window when it is alone in a Messy or Custom stage, and puts it there next time.
@MainActor
enum AppSizes {
    private static let changeTolerance: CGFloat = 3
    /// Edges within 4% of the mode's own layout count as the layout, so near misses do not become a saved size. One Navigate +/- press moves each edge 1/24 (about 4.2%), so it still counts.
    private static let layoutTolerance = 0.04
    static let modes: Set<TilingMode> = [.messy, .custom]

    static func savedRect(for window: StageWindow) -> UnitRect? {
        let settings = ConfigStore.shared.config.tilingSettings(onBuiltInScreen: StageLayout.isOnBuiltInScreen(window.frame))
        guard settings.rememberAppSizes else { return nil }
        let onBuiltInScreen = StageLayout.isOnBuiltInScreen(window.frame)
        return bundleID(of: window.pid).flatMap { AppSizeStore.shared.sizes(onBuiltInScreen: onBuiltInScreen)[$0] }
    }

    /// Saves only when the window that moved is still the only one in its stage, so a quick stage switch cannot
    /// give its place to another app.
    static func rememberIfAlone(_ windowID: CGWindowID) {
        guard !WindowAnimator.shared.isAnimating else { return appSizesLog.debug("skip: animating") }
        let visible = StageWindows.visibleSortedLeftToRight()
        guard let moved = visible.first(where: { $0.id == windowID }) else { return appSizesLog.debug("skip: window gone") }
        guard isRememberingAppSizes(onScreenOf: moved) else { return appSizesLog.debug("skip: setting off") }
        guard moved.isTileable else { return appSizesLog.debug("skip: floating window") }
        let windows = StageLayout.windowsOnSameScreen(as: moved, among: visible.tileable)
        let mode = StageLayout.mode(for: windows)
        guard windows.count == 1, let window = windows.first else { return appSizesLog.debug("skip: \(windows.count) windows") }
        guard modes.contains(mode) else { return appSizesLog.debug("skip: mode \(mode.rawValue)") }
        guard let bundleID = bundleID(of: window.pid),
              let placementArea = StageLayout.placementArea(around: window.frame, besides: StageStrip.closest(to: window.frame)),
              let expected = StageLayout.unitRects(for: windows, mode: mode).first else { return appSizesLog.debug("skip: no app or area") }
        let expectedFrame = StageLayout.frame(of: expected, in: placementArea)
        guard !isSameFrame(window.frame, expectedFrame) else { return appSizesLog.debug("skip: frame unchanged") }
        let learned = StageLayout.unitRect(of: window.frame, in: placementArea).clampedToUnitSquare()
        let onBuiltInScreen = StageLayout.isOnBuiltInScreen(window.frame)
        let layoutRect = TilingLayouts.unitRects(for: 1, mode: mode, customLayouts: ConfigStore.shared.config.tilingSettings(onBuiltInScreen: onBuiltInScreen).customLayouts).first
        let savedSize = isNearlySame(learned, layoutRect) ? nil : learned
        AppSizeStore.shared.set(savedSize, for: bundleID, onBuiltInScreen: onBuiltInScreen)
        appSizesLog.notice("\(savedSize == nil ? "forgot" : "saved", privacy: .public) \(bundleID, privacy: .public)")
    }

    static func appName(for bundleID: String) -> String {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else { return bundleID }
        return FileManager.default.displayName(atPath: url.path).replacingOccurrences(of: ".app", with: "")
    }

    private static func isRememberingAppSizes(onScreenOf window: StageWindow) -> Bool {
        ConfigStore.shared.config.tilingSettings(onBuiltInScreen: StageLayout.isOnBuiltInScreen(window.frame)).rememberAppSizes
    }

    private static func bundleID(of pid: pid_t) -> String? {
        NSRunningApplication(processIdentifier: pid)?.bundleIdentifier
    }

    static func isNearlySame(_ a: UnitRect, _ b: UnitRect?) -> Bool {
        guard let b else { return false }
        return [a.x - b.x, a.y - b.y, (a.x + a.width) - (b.x + b.width), (a.y + a.height) - (b.y + b.height)]
            .allSatisfy { abs($0) <= layoutTolerance }
    }

    private static func isSameFrame(_ a: CGRect, _ b: CGRect) -> Bool {
        abs(a.minX - b.minX) < changeTolerance && abs(a.minY - b.minY) < changeTolerance
            && abs(a.width - b.width) < changeTolerance && abs(a.height - b.height) < changeTolerance
    }
}
