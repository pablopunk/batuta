import CoreGraphics

enum ModifierKey: String, CaseIterable, Codable {
    case control, option, shift, command

    var symbol: String {
        switch self {
        case .control: "⌃"
        case .option: "⌥"
        case .shift: "⇧"
        case .command: "⌘"
        }
    }

    var eventFlag: CGEventFlags {
        switch self {
        case .control: .maskControl
        case .option: .maskAlternate
        case .shift: .maskShift
        case .command: .maskCommand
        }
    }

    static let allEventFlags: CGEventFlags = [.maskControl, .maskAlternate, .maskShift, .maskCommand]
}

enum DirectionKeys: String, CaseIterable, Codable {
    case hjkl
    case arrows

    var label: String {
        switch self {
        case .hjkl: "hjkl"
        case .arrows: "←↓↑→"
        }
    }

    var leftRightLabel: String {
        switch self {
        case .hjkl: "h l"
        case .arrows: "← →"
        }
    }

    var upDownLabel: String {
        switch self {
        case .hjkl: "k j"
        case .arrows: "↑ ↓"
        }
    }
}

enum StageConfirmMode: String, CaseIterable, Codable {
    case releaseModifier = "release"
    case pressReturn = "return"
}

/// How stages on one kind of screen are tiled. A stage can switch away from `mode` with the cycle shortcut.
struct TilingSettings: Codable, Equatable {
    var mode: TilingMode = .even
    var leaveRoomForStageManager = true

    init(mode: TilingMode = .even, leaveRoomForStageManager: Bool = true) {
        self.mode = mode
        self.leaveRoomForStageManager = leaveRoomForStageManager
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        mode = try container.decodeIfPresent(TilingMode.self, forKey: .mode) ?? .even
        leaveRoomForStageManager = try container.decodeIfPresent(Bool.self, forKey: .leaveRoomForStageManager) ?? true
    }
}

/// Everything in ~/.config/batuta/config.json. Missing keys fall back to defaults so the file can stay partial.
struct BatutaConfig: Codable, Equatable {
    var modifiers: [ModifierKey] = [.control, .command]
    /// Held on top of `modifiers` to move things instead of focusing them. Never one of `modifiers`.
    var moveModifier: ModifierKey = .shift
    var directionKeys: DirectionKeys = .arrows
    var openStageOn: StageConfirmMode = .releaseModifier
    /// Used on the laptop screen, and on every screen unless `externalScreensHaveOwnTiling` is on.
    var tiling = TilingSettings()
    var externalScreensHaveOwnTiling = false
    var externalTiling = TilingSettings()
    var tileWhenSwitchingStages = true
    /// Keyed by window count ("1" to "6"); each value has one unit rect per window, left to right.
    var customLayouts: [String: [UnitRect]] = TilingLayouts.defaultCustomLayouts
    var highlightFocusedWindow = true
    var animateWindowMoves = true
    var showMenuBarIcon = true
    /// Nil follows the navigate modifiers with Space.
    var cycleTilingModeShortcut: KeyShortcut?
    var cycleTilingModeShortcutIsCleared = false
    /// Keyed by mode name. Each shortcut toggles that mode on the current stage. None by default.
    var modeShortcuts: [String: KeyShortcut] = [:]

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = BatutaConfig()
        modifiers = try container.decodeIfPresent([ModifierKey].self, forKey: .modifiers) ?? defaults.modifiers
        moveModifier = try container.decodeIfPresent(ModifierKey.self, forKey: .moveModifier) ?? defaults.moveModifier
        if modifiers.contains(moveModifier) {
            if let freeKey = ModifierKey.allCases.first(where: { !modifiers.contains($0) }) {
                moveModifier = freeKey
            } else {
                modifiers = modifiers.filter { $0 != moveModifier }
            }
        }
        directionKeys = try container.decodeIfPresent(DirectionKeys.self, forKey: .directionKeys) ?? defaults.directionKeys
        openStageOn = try container.decodeIfPresent(StageConfirmMode.self, forKey: .openStageOn) ?? defaults.openStageOn
        customLayouts = defaults.customLayouts.merging(
            try container.decodeIfPresent([String: [UnitRect]].self, forKey: .customLayouts) ?? [:]
        ) { _, fromFile in fromFile }
        let legacy = try decoder.container(keyedBy: LegacyCodingKeys.self)
        tiling = try container.decodeIfPresent(TilingSettings.self, forKey: .tiling) ?? TilingSettings(
            mode: try legacy.decodeIfPresent(TilingMode.self, forKey: .tilingMode) ?? .even,
            leaveRoomForStageManager: try legacy.decodeIfPresent(Bool.self, forKey: .leaveRoomForStageManagerOnBuiltInScreen)
                ?? legacy.decodeIfPresent(Bool.self, forKey: .leaveRoomForStrip) ?? true
        )
        externalScreensHaveOwnTiling = try container.decodeIfPresent(Bool.self, forKey: .externalScreensHaveOwnTiling) ?? false
        externalTiling = try container.decodeIfPresent(TilingSettings.self, forKey: .externalTiling) ?? tiling
        tileWhenSwitchingStages = try container.decodeIfPresent(Bool.self, forKey: .tileWhenSwitchingStages) ?? defaults.tileWhenSwitchingStages
        highlightFocusedWindow = try container.decodeIfPresent(Bool.self, forKey: .highlightFocusedWindow) ?? defaults.highlightFocusedWindow
        animateWindowMoves = try container.decodeIfPresent(Bool.self, forKey: .animateWindowMoves) ?? defaults.animateWindowMoves
        showMenuBarIcon = try container.decodeIfPresent(Bool.self, forKey: .showMenuBarIcon) ?? defaults.showMenuBarIcon
        cycleTilingModeShortcut = try container.decodeIfPresent(KeyShortcut.self, forKey: .cycleTilingModeShortcut)
        cycleTilingModeShortcutIsCleared = try container.decodeIfPresent(Bool.self, forKey: .cycleTilingModeShortcutIsCleared) ?? false
        modeShortcuts = try container.decodeIfPresent([String: KeyShortcut].self, forKey: .modeShortcuts) ?? [:]
    }

    /// Keys from before tiling settings were grouped per screen.
    private enum LegacyCodingKeys: String, CodingKey {
        case tilingMode, leaveRoomForStrip, leaveRoomForStageManagerOnBuiltInScreen
    }

    var effectiveCycleTilingModeShortcut: KeyShortcut? {
        get {
            guard !cycleTilingModeShortcutIsCleared else { return nil }
            return cycleTilingModeShortcut ?? defaultCycleTilingModeShortcut
        }
        set {
            cycleTilingModeShortcut = newValue
            cycleTilingModeShortcutIsCleared = newValue == nil
        }
    }

    private var defaultCycleTilingModeShortcut: KeyShortcut {
        KeyShortcut(keyCode: KeyShortcut.space, keyLabel: "Space", modifiers: modifiers)
    }

    func shortcut(toggling mode: TilingMode) -> KeyShortcut? {
        modeShortcuts[mode.rawValue]
    }

    func tilingSettings(onBuiltInScreen: Bool) -> TilingSettings {
        onBuiltInScreen || !externalScreensHaveOwnTiling ? tiling : externalTiling
    }

    var requiredModifierFlags: CGEventFlags {
        modifiers.reduce(into: CGEventFlags()) { $0.insert($1.eventFlag) }
    }

    var moveModifierFlags: CGEventFlags {
        requiredModifierFlags.union(moveModifier.eventFlag)
    }

    func toggling(_ modifier: ModifierKey) -> BatutaConfig {
        guard modifier != moveModifier else { return self }
        var copy = self
        let toggled = modifiers.contains(modifier) ? modifiers.filter { $0 != modifier } : modifiers + [modifier]
        guard !toggled.isEmpty else { return self }
        copy.modifiers = ModifierKey.allCases.filter(toggled.contains)
        return copy
    }

    func choosingMoveModifier(_ modifier: ModifierKey) -> BatutaConfig {
        guard !modifiers.contains(modifier) else { return self }
        var copy = self
        copy.moveModifier = modifier
        return copy
    }
}
