import CoreGraphics

/// Modes picked with the cycle shortcut, for one stage only. A stage is known by its windows, so the choice
/// follows the stage when windows join or leave. It lives until Batuta quits.
@MainActor
enum StageTilingModes {
    private static var modeByWindowID: [CGWindowID: TilingMode] = [:]

    static func chosenMode(for windowIDs: [CGWindowID]) -> TilingMode? {
        windowIDs.lazy.compactMap { modeByWindowID[$0] }.first
    }

    static func choose(_ mode: TilingMode, for windowIDs: [CGWindowID]) {
        for id in windowIDs { modeByWindowID[id] = mode }
    }
}
