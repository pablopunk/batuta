import AppKit
import os
import ApplicationServices

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let navigator = StageNavigator()
    private let hotkeyTap = HotkeyTap()
    private let stageSwitchWatcher = StageSwitchWatcher()
    private let windowMoveWatcher = WindowMoveWatcher()
    private var permissionPollTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppUpdater.shared.startIfBundleHasUpdateFeed()
        wireHotkeysToNavigator()
        if !OnboardingWindow.hasFinished { OnboardingWindow.shared.show() }
        startHotkeysOnceAccessibilityIsGranted()
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        restoreMenuBarIconIfNeeded()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        restoreMenuBarIconIfNeeded()
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotkeyTap.stop()
    }

    private func wireHotkeysToNavigator() {
        hotkeyTap.isPickingStage = { [navigator] in navigator.isPickingStage }
        hotkeyTap.onDirection = { [navigator] in navigator.move($0) }
        hotkeyTap.onMoveDirection = { [navigator] in navigator.moveItem($0) }
        hotkeyTap.onCycleTilingMode = { [navigator] in navigator.cycleTilingModeOfCurrentStage() }
        hotkeyTap.onToggleTilingMode = { [navigator] in navigator.toggleTilingModeOfCurrentStage($0) }
        hotkeyTap.onStageNumber = { [navigator] in navigator.openStage(number: $0) }
        hotkeyTap.onResize = { [navigator] grows in
            navigator.hideStageNumbers()
            grows ? WindowResizeSteps.grow() : WindowResizeSteps.shrink()
        }
        hotkeyTap.onNavigateKeysHeld = { [navigator] held in held ? navigator.showStageNumbersSoon() : navigator.hideStageNumbers() }
        hotkeyTap.onConfirm = { [navigator] in navigator.confirmStage() }
        hotkeyTap.onCancel = { [navigator] in navigator.stopPickingStage() }
        hotkeyTap.onPointerTookOver = { [navigator] in navigator.stopPickingStage(cursor: .leaveWherePersonMovedIt) }
        hotkeyTap.onModifierReleased = { [navigator] in
            guard ConfigStore.shared.config.openStageOn == .releaseModifier else { return }
            navigator.confirmStage()
        }
    }

    private static func tileUnlessAlreadyTiled(_ windowsOnAnyScreen: [StageWindow]) {
        let windows = StageLayout.windowsOnScreenOfFocusedWindow(windowsOnAnyScreen).tileable
        guard !windows.isEmpty, !StageOrders.isTiledAlready(windows) else {
            return Logger(subsystem: "com.pablopunk.batuta", category: "stage").debug("skip tiling: \(windows.count) windows already tiled")
        }
        StageLayout.arrange(StageOrders.ordered(windows), besides: StageStrip.closest(to: windows.first?.frame))
    }

    private func startWatching() {
        hotkeyTap.start()
        stageSwitchWatcher.onStageSwitched = { windows in
            guard ConfigStore.shared.config.tileWhenSwitchingStages else { return }
            Self.tileUnlessAlreadyTiled(windows)
        }
        stageSwitchWatcher.onStageWindowsChanged = Self.tileUnlessAlreadyTiled
        stageSwitchWatcher.start()
        windowMoveWatcher.onMoveFinished = AppSizes.rememberIfAlone
        windowMoveWatcher.start()
        StageLayout.onArranged = { [stageSwitchWatcher] arranged in stageSwitchWatcher.acceptCurrentStage(including: arranged) }
    }

    private func startHotkeysOnceAccessibilityIsGranted() {
        if AXIsProcessTrusted() {
            startWatching()
            return
        }

        if OnboardingWindow.hasFinished { AccessibilityPermission.prompt() }
        permissionPollTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard AXIsProcessTrusted(), let self else { return }
                self.permissionPollTimer?.invalidate()
                self.startWatching()
            }
        }
    }

    private func restoreMenuBarIconIfNeeded() {
        ConfigStore.shared.update { $0.showMenuBarIcon = true }
    }
}

enum AccessibilityPermission {
    static var isGranted: Bool { AXIsProcessTrusted() }

    static func prompt() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    static func openSettings() {
        open("x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
    }

    static func openStageManagerSettings() {
        open("x-apple.systempreferences:com.apple.Desktop-Settings.extension")
    }

    private static func open(_ url: String) {
        guard let url = URL(string: url) else { return }
        NSWorkspace.shared.open(url)
    }
}
