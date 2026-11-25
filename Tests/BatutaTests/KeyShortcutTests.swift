import CoreGraphics
import Testing
@testable import Batuta

@Suite struct KeyShortcutTests {
    let controlCommandSpace = KeyShortcut(keyCode: KeyShortcut.space, keyLabel: "Space", modifiers: [.control, .command])

    @Test func matchesTheSameKeyAndModifiers() {
        #expect(controlCommandSpace.matches(keyCode: 49, flags: [.maskControl, .maskCommand]))
    }

    @Test func ignoresFlagsThatAreNotModifiers() {
        #expect(controlCommandSpace.matches(keyCode: 49, flags: [.maskControl, .maskCommand, .maskNumericPad, .maskSecondaryFn]))
    }

    @Test func doesNotMatchWithAnExtraOrMissingModifier() {
        #expect(!controlCommandSpace.matches(keyCode: 49, flags: [.maskControl, .maskCommand, .maskShift]))
        #expect(!controlCommandSpace.matches(keyCode: 49, flags: [.maskCommand]))
    }

    @Test func doesNotMatchAnotherKey() {
        #expect(!controlCommandSpace.matches(keyCode: 36, flags: [.maskControl, .maskCommand]))
    }

    @Test func sameKeysIgnoresTheLabelAndModifierOrder() {
        let other = KeyShortcut(keyCode: 49, keyLabel: "␣", modifiers: [.command, .control])
        #expect(controlCommandSpace.isSameKeys(as: other))
    }

    @Test func differentModifiersAreNotTheSameKeys() {
        let other = KeyShortcut(keyCode: 49, keyLabel: "Space", modifiers: [.control, .option])
        #expect(!controlCommandSpace.isSameKeys(as: other))
    }

    @Test func labelShowsModifiersInAFixedOrder() {
        #expect(KeyShortcut(keyCode: 49, keyLabel: "Space", modifiers: [.command, .control]).label == "⌃⌘ Space")
    }
}
