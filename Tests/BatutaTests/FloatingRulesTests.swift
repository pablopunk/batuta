import Testing
@testable import Batuta

@Suite struct FloatingRulesTests {
    private let normalWindow = WindowTraits(canResize: true, canMove: true, hasCloseButton: true, fullScreenButton: .enabled)
    private let settingsPane = WindowTraits(canResize: true, canMove: true, hasCloseButton: true, fullScreenButton: .disabledOrMissing)

    private func floats(_ traits: WindowTraits) -> Bool {
        FloatingRules.refusesTiling(traits)
    }

    @Test func normalWindowIsTiled() { #expect(!floats(normalWindow)) }

    @Test func windowWithoutWorkingFullScreenButtonFloats() { #expect(floats(settingsPane)) }

    @Test func windowThatCannotResizeOrMoveFloats() {
        var fixed = normalWindow
        fixed.canResize = false
        #expect(floats(fixed))
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
}
