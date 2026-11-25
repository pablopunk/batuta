import AppKit
import ApplicationServices

/// Reports when you finish moving or resizing a window of the focused app with the mouse.
/// Moves made while no mouse button is down come from Stage Manager or Batuta, so they are ignored.
@MainActor
final class WindowDragWatcher {
    var onDragFinished: (() -> Void)?

    private static let releaseCheckInterval: TimeInterval = 0.15
    private static let leftMouseButton = 1

    private var observer: AXObserver?
    private var waitsForRelease = false

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
            let watcher = Unmanaged<WindowDragWatcher>.fromOpaque(refcon).takeUnretainedValue()
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
        guard !waitsForRelease, isLeftMouseDown else { return }
        waitsForRelease = true
        checkForReleaseSoon()
    }

    private func checkForReleaseSoon() {
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.releaseCheckInterval) { [weak self] in
            guard let self else { return }
            guard !self.isLeftMouseDown else { return self.checkForReleaseSoon() }
            self.waitsForRelease = false
            self.onDragFinished?()
        }
    }

    private var isLeftMouseDown: Bool { NSEvent.pressedMouseButtons & Self.leftMouseButton != 0 }
}
