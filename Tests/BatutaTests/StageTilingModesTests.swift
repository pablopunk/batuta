import CoreGraphics
import Testing
@testable import Batuta

/// StageTilingModes keeps global state, so every test uses its own window IDs.
@MainActor
@Suite struct StageTilingModesTests {
    @Test func aStageWithoutAChoiceHasNoMode() {
        #expect(StageTilingModes.chosenMode(for: [1001, 1002]) == nil)
        #expect(StageTilingModes.modeBefore(.bsp, for: [1001, 1002]) == nil)
    }

    @Test func choosingAModeRemembersItAndTheModeBefore() {
        let stage: [CGWindowID] = [1101, 1102]
        StageTilingModes.choose(.bsp, for: stage, replacing: .even)
        #expect(StageTilingModes.chosenMode(for: stage) == .bsp)
        #expect(StageTilingModes.chosenMode(for: [1102]) == .bsp)
        #expect(StageTilingModes.modeBefore(.bsp, for: stage) == .even)
    }

    @Test func choosingTheSameModeKeepsNoModeToGoBackTo() {
        let stage: [CGWindowID] = [1201]
        StageTilingModes.choose(.even, for: stage, replacing: .even)
        #expect(StageTilingModes.chosenMode(for: stage) == .even)
        #expect(StageTilingModes.modeBefore(.even, for: stage) == nil)
    }

    @Test func togglingBackRemembersTheModeItCameFrom() {
        let stage: [CGWindowID] = [1301, 1302]
        StageTilingModes.choose(.messy, for: stage, replacing: .even)
        StageTilingModes.choose(.even, for: stage, replacing: .messy)
        #expect(StageTilingModes.chosenMode(for: stage) == .even)
        #expect(StageTilingModes.modeBefore(.even, for: stage) == .messy)
    }

    @Test func theModeBeforeIsNeverTheModeAskedAbout() {
        let stage: [CGWindowID] = [1401]
        StageTilingModes.choose(.bsp, for: stage, replacing: .even)
        #expect(StageTilingModes.modeBefore(.even, for: stage) == nil)
    }

    @Test func joiningWindowsTakeTheStageModeAndTheModeToGoBackTo() {
        let stage: [CGWindowID] = [1501]
        let joining: [CGWindowID] = [1502]
        StageTilingModes.choose(.custom, for: stage, replacing: .bsp)
        StageTilingModes.copyChoice(from: stage, to: joining)
        #expect(StageTilingModes.chosenMode(for: joining) == .custom)
        #expect(StageTilingModes.modeBefore(.custom, for: joining) == .bsp)
    }

    @Test func aJoiningWindowDropsItsOwnModeWhenTheStageHasNone() {
        let stage: [CGWindowID] = [1601]
        let joining: [CGWindowID] = [1602]
        StageTilingModes.choose(.messy, for: joining, replacing: .even)
        StageTilingModes.copyChoice(from: stage, to: joining)
        #expect(StageTilingModes.chosenMode(for: joining) == nil)
        #expect(StageTilingModes.modeBefore(.messy, for: joining) == nil)
    }
}
