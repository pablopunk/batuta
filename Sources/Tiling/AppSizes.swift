import AppKit
import os

private let appSizesLog = Logger(subsystem: "com.pablopunk.batuta", category: "appSizes")

/// Remembers where you put an app's window when it is alone in a Messy or Custom stage, and puts it there next time.
@MainActor
enum AppSizes {
    private static let changeTolerance: CGFloat = 3
    static let modes: Set<TilingMode> = [.messy, .custom]

    static func savedRect(for window: StageWindow) -> UnitRect? {
        let settings = ConfigStore.shared.config.tilingSettings(onBuiltInScreen: StageLayout.isOnBuiltInScreen(window.frame))
        return bundleID(of: window.pid).flatMap { settings.appSizes[$0] }
    }

    static func rememberLoneWindowIfMoved() {
        guard !WindowAnimator.shared.isAnimating else { return appSizesLog.debug("skip: animating") }
        let windows = StageWindows.visibleSortedLeftToRight()
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
        ConfigStore.shared.update { $0.updateTilingSettings(onBuiltInScreen: onBuiltInScreen) { $0.appSizes[bundleID] = learned } }
        appSizesLog.notice("saved \(bundleID, privacy: .public)")
    }

    static func appName(for bundleID: String) -> String {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else { return bundleID }
        return FileManager.default.displayName(atPath: url.path).replacingOccurrences(of: ".app", with: "")
    }

    private static func bundleID(of pid: pid_t) -> String? {
        NSRunningApplication(processIdentifier: pid)?.bundleIdentifier
    }

    private static func isSameFrame(_ a: CGRect, _ b: CGRect) -> Bool {
        abs(a.minX - b.minX) < changeTolerance && abs(a.minY - b.minY) < changeTolerance
            && abs(a.width - b.width) < changeTolerance && abs(a.height - b.height) < changeTolerance
    }
}
