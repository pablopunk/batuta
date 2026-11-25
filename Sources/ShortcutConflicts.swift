import CoreGraphics

/// Which recorder a shortcut belongs to, so it is not reported as taken by itself.
enum ShortcutOwner: Equatable {
    case cycleMode
    case mode(TilingMode)
}

@MainActor
enum ShortcutConflicts {
    static func actionUsing(_ shortcut: KeyShortcut, apartFrom owner: ShortcutOwner) -> String? {
        if let builtIn = HotkeyTap.builtInAction(forKeyCode: shortcut.keyCode, flags: shortcut.eventFlags) { return builtIn }
        let config = ConfigStore.shared.config
        if owner != .cycleMode, config.effectiveCycleTilingModeShortcut?.isSameKeys(as: shortcut) == true { return "Cycle mode" }
        let otherMode = TilingMode.allCases.first { mode in
            owner != .mode(mode) && config.shortcut(toggling: mode)?.isSameKeys(as: shortcut) == true
        }
        return otherMode.map { "\($0.label) mode" }
    }
}
