/// Dialogs, About boxes, settings panes and other fixed-size windows float above the tiles instead of taking one.
/// Each trait is nil when Accessibility could not read it, and an unread trait never makes a window float.
struct WindowTraits: Equatable {
    enum FullScreenButton: Equatable { case enabled, disabledOrMissing }

    var canResize: Bool?
    var canMove: Bool?
    var hasCloseButton: Bool?
    var fullScreenButton: FullScreenButton?
}

enum FloatingRules {
    static func refusesTiling(_ traits: WindowTraits) -> Bool {
        if traits.canResize == false || traits.canMove == false { return true }
        return isTitledWindowNotMeantToBeBig(traits)
    }

    /// Windows without a title bar (some terminals and editors) have no buttons at all, so they are left tiled.
    private static func isTitledWindowNotMeantToBeBig(_ traits: WindowTraits) -> Bool {
        traits.hasCloseButton == true && traits.fullScreenButton == .disabledOrMissing
    }
}

extension Array where Element == StageWindow {
    var tileable: [StageWindow] { filter(\.isTileable) }
}
