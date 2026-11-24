import AppKit
import CoreGraphics

enum ModifierKey: Int, CaseIterable {
    case control = 1
    case option = 2
    case shift = 4
    case command = 8

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

    static let hyperMask = allCases.reduce(0) { $0 | $1.rawValue }
    static let allEventFlags: CGEventFlags = [.maskControl, .maskAlternate, .maskShift, .maskCommand]
}

enum StageConfirmMode: String, CaseIterable {
    case releaseModifier
    case pressReturn
}

enum SettingsKeys {
    static let modifierMask = "modifierMask"
    static let stageConfirmMode = "stageConfirmMode"
    static let highlightFocusedWindow = "highlightFocusedWindow"
    static let showMenuBarIcon = "showMenuBarIcon"
}

enum Settings {
    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            SettingsKeys.modifierMask: ModifierKey.hyperMask,
            SettingsKeys.stageConfirmMode: StageConfirmMode.releaseModifier.rawValue,
            SettingsKeys.highlightFocusedWindow: true,
            SettingsKeys.showMenuBarIcon: true,
        ])
    }

    static var requiredModifierFlags: CGEventFlags {
        let mask = UserDefaults.standard.integer(forKey: SettingsKeys.modifierMask)
        return ModifierKey.allCases
            .filter { mask & $0.rawValue != 0 }
            .reduce(into: CGEventFlags()) { $0.insert($1.eventFlag) }
    }

    static var stageConfirmMode: StageConfirmMode {
        StageConfirmMode(rawValue: UserDefaults.standard.string(forKey: SettingsKeys.stageConfirmMode) ?? "") ?? .releaseModifier
    }

    static var highlightFocusedWindow: Bool {
        UserDefaults.standard.bool(forKey: SettingsKeys.highlightFocusedWindow)
    }
}
