import Testing
@testable import Batuta

@Suite struct FloatingRulesTests {
    private let normalWindow = WindowTraits(canResize: true, canMove: true, hasCloseButton: true, fullScreenButton: .enabled)
    private let settingsPane = WindowTraits(canResize: true, canMove: true, hasCloseButton: true, fullScreenButton: .disabledOrMissing)

    private func floats(_ traits: WindowTraits, _ bundleID: String? = "com.example.app") -> Bool {
        FloatingRules.refusesTiling(traits, bundleID: bundleID)
    }

    @Test func normalWindowIsTiled() { #expect(!floats(normalWindow)) }

    @Test func windowWithoutWorkingFullScreenButtonFloats() { #expect(floats(settingsPane)) }

    @Test func windowThatCannotResizeOrMoveFloatsEvenInAlwaysTiledApps() {
        var fixed = normalWindow
        fixed.canResize = false
        #expect(floats(fixed, "com.google.Chrome"))
        var pinned = normalWindow
        pinned.canMove = false
        #expect(floats(pinned))
    }

    @Test func unreadableTraitsKeepTheWindowTiled() {
        #expect(!floats(WindowTraits()))
        #expect(!floats(WindowTraits(canResize: true, canMove: true, hasCloseButton: true, fullScreenButton: nil)))
    }

    @Test func windowWithoutTitleBarButtonsIsTiled() {
        #expect(!floats(WindowTraits(canResize: true, canMove: true, hasCloseButton: false, fullScreenButton: .disabledOrMissing)))
    }

    @Test func alwaysTiledAppsKeepWindowsWithoutFullScreenButtonTiled() {
        #expect(!floats(settingsPane, "com.google.Chrome"))
    }

    @Test func alwaysFloatingAppsFloat() {
        #expect(floats(normalWindow, "com.apple.iphonesimulator"))
    }
}
