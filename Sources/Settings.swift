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

/// Everything in ~/.config/batuta/config.json. Missing keys fall back to defaults so the file can stay partial.
struct BatutaConfig: Codable, Equatable {
    var modifiers: [ModifierKey] = [.control, .option, .command]
    var directionKeys: DirectionKeys = .hjkl
    var openStageOn: StageConfirmMode = .releaseModifier
    var highlightFocusedWindow = true
    var animateWindowMoves = true
    var showMenuBarIcon = true

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = BatutaConfig()
        modifiers = try container.decodeIfPresent([ModifierKey].self, forKey: .modifiers) ?? defaults.modifiers
        directionKeys = try container.decodeIfPresent(DirectionKeys.self, forKey: .directionKeys) ?? defaults.directionKeys
        openStageOn = try container.decodeIfPresent(StageConfirmMode.self, forKey: .openStageOn) ?? defaults.openStageOn
        highlightFocusedWindow = try container.decodeIfPresent(Bool.self, forKey: .highlightFocusedWindow) ?? defaults.highlightFocusedWindow
        animateWindowMoves = try container.decodeIfPresent(Bool.self, forKey: .animateWindowMoves) ?? defaults.animateWindowMoves
        showMenuBarIcon = try container.decodeIfPresent(Bool.self, forKey: .showMenuBarIcon) ?? defaults.showMenuBarIcon
    }

    var requiredModifierFlags: CGEventFlags {
        modifiers.reduce(into: CGEventFlags()) { $0.insert($1.eventFlag) }
    }

    func toggling(_ modifier: ModifierKey) -> BatutaConfig {
        var copy = self
        let toggled = modifiers.contains(modifier) ? modifiers.filter { $0 != modifier } : modifiers + [modifier]
        guard !toggled.isEmpty else { return self }
        copy.modifiers = ModifierKey.allCases.filter(toggled.contains)
        return copy
    }
}
