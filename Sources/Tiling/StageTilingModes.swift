import CoreGraphics

/// Modes picked with a shortcut, for one stage only. A stage is known by its windows, so the choice
/// follows the stage when windows join or leave. It lives until Batuta quits.
@MainActor
enum StageTilingModes {
    private static var modeByWindowID: [CGWindowID: TilingMode] = [:]
    private static var previousModeByWindowID: [CGWindowID: TilingMode] = [:]

    static func chosenMode(for windowIDs: [CGWindowID]) -> TilingMode? {
        windowIDs.lazy.compactMap { modeByWindowID[$0] }.first
    }

    /// The mode the stage had before it switched to `mode`, so a mode shortcut can toggle back.
    static func modeBefore(_ mode: TilingMode, for windowIDs: [CGWindowID]) -> TilingMode? {
        windowIDs.lazy.compactMap { previousModeByWindowID[$0] }.first { $0 != mode }
    }

    static func choose(_ mode: TilingMode, for windowIDs: [CGWindowID], replacing previousMode: TilingMode) {
        for id in windowIDs {
            modeByWindowID[id] = mode
            if previousMode != mode { previousModeByWindowID[id] = previousMode }
        }
    }

    /// Windows that join a stage take its chosen mode, and the mode to toggle back to.
    static func copyChoice(from stageWindowIDs: [CGWindowID], to joiningWindowIDs: [CGWindowID]) {
        let chosen = chosenMode(for: stageWindowIDs)
        let previous = stageWindowIDs.lazy.compactMap { previousModeByWindowID[$0] }.first
        for id in joiningWindowIDs {
            if let chosen { modeByWindowID[id] = chosen }
            if let previous { previousModeByWindowID[id] = previous }
        }
    }
}
