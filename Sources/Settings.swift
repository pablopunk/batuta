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

enum StageConfirmMode: String, CaseIterable, Codable {
    case releaseModifier = "release"
    case pressReturn = "return"
}

/// Everything in ~/.config/batuta/config.json. Missing keys fall back to defaults so the file can stay partial.
struct BatutaConfig: Codable, Equatable {
    var modifiers: [ModifierKey] = ModifierKey.allCases
    var openStageOn: StageConfirmMode = .releaseModifier
    var highlightFocusedWindow = true
    var showMenuBarIcon = true

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = BatutaConfig()
        modifiers = try container.decodeIfPresent([ModifierKey].self, forKey: .modifiers) ?? defaults.modifiers
        openStageOn = try container.decodeIfPresent(StageConfirmMode.self, forKey: .openStageOn) ?? defaults.openStageOn
        highlightFocusedWindow = try container.decodeIfPresent(Bool.self, forKey: .highlightFocusedWindow) ?? defaults.highlightFocusedWindow
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
