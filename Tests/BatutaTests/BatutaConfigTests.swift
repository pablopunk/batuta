import Foundation
import Testing
@testable import Batuta

@Suite struct BatutaConfigTests {
    private func decode(_ json: String) throws -> BatutaConfig {
        try JSONDecoder().decode(BatutaConfig.self, from: Data(json.utf8))
    }

    private let appSizesJSON = #"{"com.apple.Safari": {"x": 0.1, "y": 0.2, "width": 0.5, "height": 0.6}}"#
    private let safariRect = UnitRect(x: 0.1, y: 0.2, width: 0.5, height: 0.6)

    @Test func emptyJSONGivesTheDefaults() throws {
        let config = try decode("{}")
        #expect(config == BatutaConfig())
        #expect(config.modifiers == [.control, .command])
        #expect(config.moveModifier == .shift)
        #expect(config.tiling == TilingSettings())
        #expect(config.tiling.mode == .even)
        #expect(config.tiling.customLayouts == TilingLayouts.defaultCustomLayouts)
    }

    @Test func legacyTilingModeAndStripRoomMoveIntoTiling() throws {
        let config = try decode(#"{"tilingMode": "bsp", "leaveRoomForStrip": false}"#)
        #expect(config.tiling.mode == .bsp)
        #expect(!config.tiling.leaveRoomForStageManager)
        #expect(config.externalTiling == config.tiling)
    }

    @Test func legacyBuiltInScreenRoomWinsOverStripRoom() throws {
        let config = try decode(#"{"leaveRoomForStageManagerOnBuiltInScreen": true, "leaveRoomForStrip": false}"#)
        #expect(config.tiling.leaveRoomForStageManager)
    }

    @Test func legacyKeysAreIgnoredWhenTilingIsPresent() throws {
        let config = try decode(#"{"tilingMode": "bsp", "tiling": {"mode": "messy"}}"#)
        #expect(config.tiling.mode == .messy)
        #expect(config.tiling.leaveRoomForStageManager)
    }

    @Test func aMoveModifierThatIsANavigateModifierBecomesTheFirstFreeOne() throws {
        let config = try decode(#"{"modifiers": ["control", "shift"], "moveModifier": "shift"}"#)
        #expect(config.modifiers == [.control, .shift])
        #expect(config.moveModifier == .option)
    }

    @Test func withEveryModifierTakenTheMoveModifierLeavesTheNavigateModifiers() throws {
        let config = try decode(#"{"modifiers": ["control", "option", "shift", "command"], "moveModifier": "command"}"#)
        #expect(config.moveModifier == .command)
        #expect(config.modifiers == [.control, .option, .shift])
    }

    @Test func customLayoutsFromTheFileMergeWithTheDefaults() throws {
        let config = try decode(#"{"customLayouts": {"1": [{"x": 0.2, "y": 0, "width": 0.6, "height": 1}]}}"#)
        #expect(config.tiling.customLayouts["1"] == [UnitRect(x: 0.2, y: 0, width: 0.6, height: 1)])
        #expect(config.externalTiling.customLayouts["1"] == [UnitRect(x: 0.2, y: 0, width: 0.6, height: 1)])
        #expect(config.tiling.customLayouts["3"] == TilingLayouts.evenGrid(3))
    }

    @Test func theCycleShortcutDefaultsToSpaceWithTheNavigateModifiers() throws {
        let config = try decode(#"{"modifiers": ["option"]}"#)
        #expect(config.effectiveCycleTilingModeShortcut == KeyShortcut(keyCode: KeyShortcut.space, keyLabel: "Space", modifiers: [.option]))
    }

    @Test func aClearedCycleShortcutHasNoShortcut() throws {
        let config = try decode(#"{"cycleTilingModeShortcutIsCleared": true}"#)
        #expect(config.effectiveCycleTilingModeShortcut == nil)
    }

    @Test func settingTheCycleShortcutToNilClearsIt() {
        var config = BatutaConfig()
        config.effectiveCycleTilingModeShortcut = nil
        #expect(config.cycleTilingModeShortcutIsCleared)
        let shortcut = KeyShortcut(keyCode: 3, keyLabel: "F", modifiers: [.option])
        config.effectiveCycleTilingModeShortcut = shortcut
        #expect(!config.cycleTilingModeShortcutIsCleared)
        #expect(config.effectiveCycleTilingModeShortcut == shortcut)
    }

    @Test func externalScreensUseLaptopSettingsUnlessTheyHaveTheirOwn() {
        var config = BatutaConfig()
        config.tiling.mode = .bsp
        config.externalTiling.mode = .messy
        #expect(config.tilingSettings(onBuiltInScreen: false).mode == .bsp)
        config.externalScreensHaveOwnTiling = true
        #expect(config.tilingSettings(onBuiltInScreen: false).mode == .messy)
        #expect(config.tilingSettings(onBuiltInScreen: true).mode == .bsp)
    }

    @Test func encodingThenDecodingGivesTheSameConfig() throws {
        var config = BatutaConfig()
        config.modifiers = [.option, .command]
        config.moveModifier = .control
        config.directionKeys = .hjkl
        config.openStageOn = .pressReturn
        config.tiling = TilingSettings(mode: .custom, leaveRoomForStageManager: false)
        config.externalScreensHaveOwnTiling = true
        config.externalTiling = TilingSettings(mode: .bsp)
        config.tileWhenSwitchingStages = false
        config.tiling.customLayouts["2"] = [UnitRect(x: 0, y: 0, width: 0.3, height: 1), UnitRect(x: 0.3, y: 0, width: 0.7, height: 1)]
        config.highlightFocusedWindow = false
        config.animateWindowMoves = false
        config.showMenuBarIcon = false
        config.cycleTilingModeShortcut = KeyShortcut(keyCode: 3, keyLabel: "F", modifiers: [.option])
        config.modeShortcuts = ["bsp": KeyShortcut(keyCode: 11, keyLabel: "B", modifiers: [.control, .option])]
        let decoded = try JSONDecoder().decode(BatutaConfig.self, from: JSONEncoder().encode(config))
        #expect(decoded == config)
        #expect(decoded.shortcut(toggling: .bsp) == config.modeShortcuts["bsp"])
    }

    @Test func togglingTheMoveModifierDoesNothing() {
        let config = BatutaConfig()
        #expect(config.toggling(.shift) == config)
    }

    @Test func togglingOffTheLastNavigateModifierDoesNothing() {
        var config = BatutaConfig()
        config.modifiers = [.command]
        #expect(config.toggling(.command) == config)
    }

    @Test func choosingANavigateModifierAsMoveModifierDoesNothing() {
        let config = BatutaConfig()
        #expect(config.choosingMoveModifier(.control) == config)
        #expect(config.choosingMoveModifier(.option).moveModifier == .option)
    }
}
