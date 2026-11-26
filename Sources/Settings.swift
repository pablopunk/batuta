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
    var rememberAppSizes = false
    /// Keyed by window count ("1" to "6"); each value has one unit rect per window, left to right.
    var customLayouts: [String: [UnitRect]] = TilingLayouts.defaultCustomLayouts

    init(mode: TilingMode = .even, leaveRoomForStageManager: Bool = true) {
        self.mode = mode
        self.leaveRoomForStageManager = leaveRoomForStageManager
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        mode = try container.decodeIfPresent(TilingMode.self, forKey: .mode) ?? .even
        leaveRoomForStageManager = try container.decodeIfPresent(Bool.self, forKey: .leaveRoomForStageManager) ?? true
        rememberAppSizes = try container.decodeIfPresent(Bool.self, forKey: .rememberAppSizes) ?? false
        customLayouts = TilingLayouts.defaultCustomLayouts.merging(
            try container.decodeIfPresent([String: [UnitRect]].self, forKey: .customLayouts) ?? [:]
        ) { _, fromFile in fromFile }
    }

    private enum CodingKeys: String, CodingKey {
        case mode, leaveRoomForStageManager, rememberAppSizes, customLayouts
    }

    /// Only layouts you drew go in the file; the rest are the defaults.
    private var customLayoutsDrawnByYou: [String: [UnitRect]] {
        customLayouts.filter { TilingLayouts.defaultCustomLayouts[$0.key] != $0.value }
    }

    /// Leaves out default layouts, so the config only shows the ones you drew.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(mode, forKey: .mode)
        try container.encode(leaveRoomForStageManager, forKey: .leaveRoomForStageManager)
        try container.encode(rememberAppSizes, forKey: .rememberAppSizes)
        if !customLayoutsDrawnByYou.isEmpty { try container.encode(customLayoutsDrawnByYou, forKey: .customLayouts) }
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
    var highlightFocusedWindow = true
    var animateWindowMoves = true
    var showMenuBarIcon = true
    /// Nil follows the navigate modifiers with Space.
    var cycleTilingModeShortcut: KeyShortcut?
    var cycleTilingModeShortcutIsCleared = false
    /// Keyed by mode name. Each shortcut toggles that mode on the current stage. None by default.
    var modeShortcuts: [String: KeyShortcut] = [:]
    /// Bundle IDs whose windows never get tiled.
    var floatingApps: [String] = []
    /// Bundle IDs whose resizable windows always get tiled, even without a working full-screen button.
    var tiledApps: [String] = FloatingRules.defaultTiledApps

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
        let legacy = try decoder.container(keyedBy: LegacyCodingKeys.self)
        tiling = try container.decodeIfPresent(TilingSettings.self, forKey: .tiling) ?? TilingSettings(
            mode: try legacy.decodeIfPresent(TilingMode.self, forKey: .tilingMode) ?? .even,
            leaveRoomForStageManager: try legacy.decodeIfPresent(Bool.self, forKey: .leaveRoomForStageManagerOnBuiltInScreen)
                ?? legacy.decodeIfPresent(Bool.self, forKey: .leaveRoomForStrip) ?? true
        )
        externalScreensHaveOwnTiling = try container.decodeIfPresent(Bool.self, forKey: .externalScreensHaveOwnTiling) ?? false
        externalTiling = try container.decodeIfPresent(TilingSettings.self, forKey: .externalTiling) ?? tiling
        if let topLevelCustomLayouts = try legacy.decodeIfPresent([String: [UnitRect]].self, forKey: .customLayouts) {
            let laptopKeysInFile = try container.decodeIfPresent(CustomLayoutKeysInFile.self, forKey: .tiling)?.keys ?? []
            let externalKeysInFile = try container.decodeIfPresent(CustomLayoutKeysInFile.self, forKey: .externalTiling)?.keys ?? laptopKeysInFile
            for (key, rects) in topLevelCustomLayouts {
                if !laptopKeysInFile.contains(key) { tiling.customLayouts[key] = rects }
                if !externalKeysInFile.contains(key) { externalTiling.customLayouts[key] = rects }
            }
        }
        tileWhenSwitchingStages = try container.decodeIfPresent(Bool.self, forKey: .tileWhenSwitchingStages) ?? defaults.tileWhenSwitchingStages
        highlightFocusedWindow = try container.decodeIfPresent(Bool.self, forKey: .highlightFocusedWindow) ?? defaults.highlightFocusedWindow
        animateWindowMoves = try container.decodeIfPresent(Bool.self, forKey: .animateWindowMoves) ?? defaults.animateWindowMoves
        showMenuBarIcon = try container.decodeIfPresent(Bool.self, forKey: .showMenuBarIcon) ?? defaults.showMenuBarIcon
        cycleTilingModeShortcut = try container.decodeIfPresent(KeyShortcut.self, forKey: .cycleTilingModeShortcut)
        cycleTilingModeShortcutIsCleared = try container.decodeIfPresent(Bool.self, forKey: .cycleTilingModeShortcutIsCleared) ?? false
        modeShortcuts = try container.decodeIfPresent([String: KeyShortcut].self, forKey: .modeShortcuts) ?? [:]
        floatingApps = try container.decodeIfPresent([String].self, forKey: .floatingApps) ?? defaults.floatingApps
        tiledApps = try container.decodeIfPresent([String].self, forKey: .tiledApps) ?? defaults.tiledApps
    }

    /// The window counts a tiling section of the file sets itself, which a legacy top-level layout must not replace.
    private struct CustomLayoutKeysInFile: Decodable {
        let keys: Set<String>

        private enum CodingKeys: String, CodingKey { case customLayouts }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            keys = Set((try container.decodeIfPresent([String: [UnitRect]].self, forKey: .customLayouts) ?? [:]).keys)
        }
    }

    /// Keys from before tiling settings were grouped per screen.
    private enum LegacyCodingKeys: String, CodingKey {
        case tilingMode, leaveRoomForStrip, leaveRoomForStageManagerOnBuiltInScreen, customLayouts
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
        usesLaptopTiling(onBuiltInScreen: onBuiltInScreen) ? tiling : externalTiling
    }

    mutating func updateTilingSettings(onBuiltInScreen: Bool, _ change: (inout TilingSettings) -> Void) {
        if usesLaptopTiling(onBuiltInScreen: onBuiltInScreen) { change(&tiling) } else { change(&externalTiling) }
    }

    func usesLaptopTiling(onBuiltInScreen: Bool) -> Bool {
        onBuiltInScreen || !externalScreensHaveOwnTiling
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
