import AppKit

/// Reports when one of the given windows leaves the screen. Closing a window often keeps the same app active,
/// and many apps only hide the window instead of destroying it, so neither focus changes nor AX notices it.
/// The on-screen window list is cheap to read, so it is checked a few times a second.
@MainActor
final class WindowCloseWatcher {
    var onWindowClosed: (() -> Void)?

    private static let checkInterval: TimeInterval = 0.5

    private var watchedWindowIDs = Set<CGWindowID>()
    private var timer: Timer?

    func watch(_ windows: [StageWindow]) {
        watchedWindowIDs = Set(windows.map(\.id))
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: Self.checkInterval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.reportIfAWatchedWindowLeftTheScreen() }
        }
    }

    private func reportIfAWatchedWindowLeftTheScreen() {
        guard !watchedWindowIDs.isEmpty else { return }
        let onScreen = Self.onScreenWindowIDs()
        guard !watchedWindowIDs.isSubset(of: onScreen) else { return }
        watchedWindowIDs.formIntersection(onScreen)
        onWindowClosed?()
    }

    private static func onScreenWindowIDs() -> Set<CGWindowID> {
        let info = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []
        return Set(info.compactMap { $0[kCGWindowNumber as String] as? CGWindowID })
    }
}
