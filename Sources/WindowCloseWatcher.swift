import AppKit
import ApplicationServices

/// Reports when one of the given windows closes. Closing a window often keeps the same app active,
/// so neither app activation nor focus changes would notice it.
@MainActor
final class WindowCloseWatcher {
    var onWindowClosed: (() -> Void)?

    private var observersByPID: [pid_t: AXObserver] = [:]
    private var watchedWindowIDs = Set<CGWindowID>()

    func watch(_ windows: [StageWindow]) {
        let ids = Set(windows.map(\.id))
        guard ids != watchedWindowIDs else { return }
        stopWatching()
        watchedWindowIDs = ids
        let refcon = Unmanaged.passUnretained(self).toOpaque()
        for (pid, windowsOfApp) in Dictionary(grouping: windows, by: \.pid) {
            var observer: AXObserver?
            let callback: AXObserverCallback = { _, _, _, refcon in
                guard let refcon else { return }
                let watcher = Unmanaged<WindowCloseWatcher>.fromOpaque(refcon).takeUnretainedValue()
                MainActor.assumeIsolated { watcher.onWindowClosed?() }
            }
            guard AXObserverCreate(pid, callback, &observer) == .success, let observer else { continue }
            for window in windowsOfApp {
                AXObserverAddNotification(observer, window.element, kAXUIElementDestroyedNotification as CFString, refcon)
            }
            CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .defaultMode)
            observersByPID[pid] = observer
        }
    }

    private func stopWatching() {
        for observer in observersByPID.values {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .defaultMode)
        }
        observersByPID = [:]
        watchedWindowIDs = []
    }
}
