import AppKit
import ApplicationServices

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let navigator = StageNavigator()
    private let hotkeyTap = HotkeyTap()
    private let stageSwitchWatcher = StageSwitchWatcher()
    private var permissionPollTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        wireHotkeysToNavigator()
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
        hotkeyTap.onConfirm = { [navigator] in navigator.confirmStage() }
        hotkeyTap.onCancel = { [navigator] in navigator.stopPickingStage() }
        hotkeyTap.onPointerTookOver = { [navigator] in navigator.stopPickingStage(cursor: .leaveWherePersonMovedIt) }
        hotkeyTap.onModifierReleased = { [navigator] in
            guard ConfigStore.shared.config.openStageOn == .releaseModifier else { return }
            navigator.confirmStage()
        }
    }

    private func startWatching() {
        hotkeyTap.start()
        stageSwitchWatcher.onStageSwitched = { windows in
            guard ConfigStore.shared.config.tileWhenSwitchingStages, !StageOrders.isTiledAlready(windows) else { return }
            StageLayout.arrange(StageOrders.ordered(windows), besides: StageStrip.closest(to: windows.first?.frame))
        }
        stageSwitchWatcher.start()
        StageLayout.onArranged = { [stageSwitchWatcher] in stageSwitchWatcher.acceptCurrentStage() }
    }

    private func startHotkeysOnceAccessibilityIsGranted() {
        if AXIsProcessTrusted() {
            startWatching()
            return
        }

        AccessibilityPermission.prompt()
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
