import AppKit
import ApplicationServices
import os

private let stageLog = Logger(subsystem: "com.pablopunk.batuta", category: "stage")

/// macOS has no "stage changed" event, so a switch is inferred: when the app or its focused window changes,
/// the windows shown full size are read again once Stage Manager settles. Almost no window in common means another stage.
@MainActor
final class StageSwitchWatcher {
    var onStageSwitched: (([StageWindow]) -> Void)?
    /// Windows joined or left the stage you are in, for example when an app quits.
    var onStageWindowsChanged: (([StageWindow]) -> Void)?

    private static let settleInterval: TimeInterval = 0.1
    private static let settleAttempts = 15

    private var lastStageWindowIDs = Set<CGWindowID>()
    private var focusObserver: AXObserver?
    private var checkGeneration = 0
    private let closeWatcher = WindowCloseWatcher()

    func start() {
        closeWatcher.onWindowClosed = { [weak self] in self?.checkSoon() }
        rememberCurrentStage(StageWindows.visibleSortedLeftToRight())
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main) { [weak self] notification in
            let pid = (notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication)?.processIdentifier
            MainActor.assumeIsolated {
                if let pid { self?.watchFocusedWindow(of: pid) }
                self?.checkSoon()
            }
        }
        if let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier { watchFocusedWindow(of: pid) }
    }

    /// Batuta tiles on its own after it adds or removes a window, so it reports the new set instead of a switch.
    /// A window still resizing is not read as shown, so the windows Batuta just tiled are added to what is read.
    func acceptCurrentStage(including arranged: [StageWindow]) {
        let visible = StageWindows.visibleSortedLeftToRight()
        let visibleIDs = Set(visible.map(\.id))
        rememberCurrentStage(visible + arranged.filter { !visibleIDs.contains($0.id) })
    }

    private func rememberCurrentStage(_ windows: [StageWindow]) {
        lastStageWindowIDs = Set(windows.map(\.id))
        closeWatcher.watch(windows)
    }

    private func checkSoon() {
        checkGeneration += 1
        waitUntilStageSettles(generation: checkGeneration, previous: nil, attemptsLeft: Self.settleAttempts)
    }

    private func waitUntilStageSettles(generation: Int, previous: [CGWindowID]?, attemptsLeft: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.settleInterval) { [weak self] in
            guard let self, generation == self.checkGeneration else { return }
            guard !WindowAnimator.shared.isAnimating else {
                self.waitUntilStageSettles(generation: generation, previous: nil, attemptsLeft: attemptsLeft)
                return
            }
            let windows = StageWindows.visibleSortedLeftToRight()
            let ids = windows.map(\.id)
            let isSettled = !ids.isEmpty && ids == previous
            guard isSettled || attemptsLeft == 0 else {
                self.waitUntilStageSettles(generation: generation, previous: ids, attemptsLeft: attemptsLeft - 1)
                return
            }
            self.compareWithLastStage(windows)
        }
    }

    private func compareWithLastStage(_ windows: [StageWindow]) {
        let ids = Set(windows.map(\.id))
        stageLog.notice("compare \(ids.count) windows with \(self.lastStageWindowIDs.count)")
        guard !ids.isEmpty, ids != lastStageWindowIDs else { return }
        let isAnotherStage = ids.intersection(lastStageWindowIDs).count * 2 < max(ids.count, lastStageWindowIDs.count)
        rememberCurrentStage(windows)
        if isAnotherStage { onStageSwitched?(windows) } else { onStageWindowsChanged?(windows) }
    }

    /// Two stages can share an app, so a switch may not activate a new app; the focused window still changes.
    private func watchFocusedWindow(of pid: pid_t) {
        if let focusObserver {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(focusObserver), .defaultMode)
        }
        focusObserver = nil
        var observer: AXObserver?
        let callback: AXObserverCallback = { _, _, _, refcon in
            guard let refcon else { return }
            let watcher = Unmanaged<StageSwitchWatcher>.fromOpaque(refcon).takeUnretainedValue()
            MainActor.assumeIsolated { watcher.checkSoon() }
        }
        guard AXObserverCreate(pid, callback, &observer) == .success, let observer else { return }
        AXObserverAddNotification(observer, AXUIElementCreateApplication(pid), kAXFocusedWindowChangedNotification as CFString, Unmanaged.passUnretained(self).toOpaque())
        CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .defaultMode)
        focusObserver = observer
    }
}
