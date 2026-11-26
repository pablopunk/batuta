import Testing
@testable import Batuta

@Suite struct FloatingRulesTests {
    private let normalWindow = WindowTraits(canResize: true, canMove: true, hasCloseButton: true, fullScreenButton: .enabled)
    private let settingsPane = WindowTraits(canResize: true, canMove: true, hasCloseButton: true, fullScreenButton: .disabledOrMissing)

    private func floats(_ traits: WindowTraits, _ bundleID: String? = "com.example.app", floating: Set<String> = [], tiled: Set<String> = []) -> Bool {
        FloatingRules.refusesTiling(traits, bundleID: bundleID, floatingApps: floating, tiledApps: tiled)
    }

    @Test func normalWindowIsTiled() { #expect(!floats(normalWindow)) }

    @Test func windowWithoutWorkingFullScreenButtonFloats() { #expect(floats(settingsPane)) }

    @Test func windowThatCannotResizeOrMoveFloatsEvenWhenItsAppIsTiled() {
        var fixed = normalWindow
        fixed.canResize = false
        #expect(floats(fixed, tiled: ["com.example.app"]))
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

    @Test func floatingAppsFloatAndWinOverTiledApps() {
        #expect(floats(normalWindow, floating: ["com.example.app"], tiled: ["com.example.app"]))
    }

    @Test func tiledAppsKeepWindowsWithoutFullScreenButtonTiled() {
        #expect(!floats(settingsPane, tiled: ["com.example.app"]))
    }

    @Test func builtInFloatingAppsFloatUnlessTheUserTilesThem() {
        #expect(floats(normalWindow, "com.apple.iphonesimulator"))
        #expect(!floats(normalWindow, "com.apple.iphonesimulator", tiled: ["com.apple.iphonesimulator"]))
    }
}
