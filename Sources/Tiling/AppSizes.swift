import AppKit

/// Remembers where you put an app's window when it is alone in a Messy stage, and puts it there next time.
@MainActor
enum AppSizes {
    private static let changeTolerance: CGFloat = 3

    static func savedRect(for window: StageWindow) -> UnitRect? {
        bundleID(of: window.pid).flatMap { ConfigStore.shared.config.appSizes[$0] }
    }

    static func rememberLoneMessyWindowIfMoved() {
        guard !WindowAnimator.shared.isAnimating else { return }
        let windows = StageWindows.visibleSortedLeftToRight()
        guard windows.count == 1, let window = windows.first, StageLayout.mode(for: windows) == .messy,
              let bundleID = bundleID(of: window.pid),
              let placementArea = StageLayout.placementArea(around: window.frame, besides: StageStrip.closest(to: window.frame)),
              let expected = StageLayout.unitRects(for: windows, mode: .messy).first else { return }
        let expectedFrame = StageLayout.frame(of: expected, in: placementArea)
        guard !isSameFrame(window.frame, expectedFrame) else { return }
        let learned = StageLayout.unitRect(of: window.frame, in: placementArea).clampedToUnitSquare()
        ConfigStore.shared.update { $0.appSizes[bundleID] = learned }
    }

    static func forget(_ bundleID: String) {
        ConfigStore.shared.update { $0.appSizes[bundleID] = nil }
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
