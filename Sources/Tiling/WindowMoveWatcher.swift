import AppKit
import ApplicationServices

/// Reports when a window of the focused app stops moving or resizing, by hand or with a tool like Swift Shift.
/// Moves that end right after a Batuta animation are Batuta's own, so they are ignored.
@MainActor
final class WindowMoveWatcher {
    var onMoveFinished: (() -> Void)?

    private static let quietInterval: TimeInterval = 0.5

    private var observer: AXObserver?
    private var quietGeneration = 0

    func start() {
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main) { [weak self] notification in
            let pid = (notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication)?.processIdentifier
            MainActor.assumeIsolated { if let pid { self?.watch(pid) } }
        }
        if let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier { watch(pid) }
    }

    private func watch(_ pid: pid_t) {
        if let observer { CFRunLoopRemoveSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .defaultMode) }
        observer = nil
        var newObserver: AXObserver?
        let callback: AXObserverCallback = { _, _, _, refcon in
            guard let refcon else { return }
            let watcher = Unmanaged<WindowMoveWatcher>.fromOpaque(refcon).takeUnretainedValue()
            MainActor.assumeIsolated { watcher.windowMovedOrResized() }
        }
        guard AXObserverCreate(pid, callback, &newObserver) == .success, let newObserver else { return }
        let app = AXUIElementCreateApplication(pid)
        let refcon = Unmanaged.passUnretained(self).toOpaque()
        for notification in [kAXWindowMovedNotification, kAXWindowResizedNotification] {
            AXObserverAddNotification(newObserver, app, notification as CFString, refcon)
        }
        CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(newObserver), .defaultMode)
        observer = newObserver
    }

    private func windowMovedOrResized() {
        quietGeneration += 1
        let generation = quietGeneration
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.quietInterval) { [weak self] in
            guard let self, generation == self.quietGeneration, !Self.batutaMovedWindowsJustNow else { return }
            self.onMoveFinished?()
        }
    }

    private static var batutaMovedWindowsJustNow: Bool {
        let animator = WindowAnimator.shared
        return animator.isAnimating || CACurrentMediaTime() - animator.lastLandedAt < quietInterval + 0.2
    }
}
