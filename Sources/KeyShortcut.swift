import AppKit

/// A key with its modifiers, as saved in the config. `keyLabel` is only for showing it.
struct KeyShortcut: Codable, Equatable {
    var keyCode: Int64
    var keyLabel: String
    var modifiers: [ModifierKey]

    static let space: Int64 = 49

    var label: String {
        ModifierKey.allCases.filter(modifiers.contains).map(\.symbol).joined() + " " + keyLabel
    }

    var eventFlags: CGEventFlags {
        modifiers.reduce(into: CGEventFlags()) { $0.insert($1.eventFlag) }
    }

    func matches(keyCode: Int64, flags: CGEventFlags) -> Bool {
        keyCode == self.keyCode && flags.intersection(ModifierKey.allEventFlags) == eventFlags
    }

    func isSameKeys(as other: KeyShortcut) -> Bool {
        matches(keyCode: other.keyCode, flags: other.eventFlags)
    }
}

extension KeyShortcut {
    private static let namedKeys: [UInt16: String] = [
        49: "Space", 36: "↩", 48: "⇥", 51: "⌫", 117: "⌦", 53: "Esc",
        123: "←", 124: "→", 125: "↓", 126: "↑", 115: "Home", 119: "End", 116: "PgUp", 121: "PgDn",
        122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6", 98: "F7", 100: "F8", 101: "F9", 109: "F10", 103: "F11", 111: "F12",
    ]

    /// Nil for a key pressed without any modifier, so a plain key never becomes a global shortcut.
    init?(recording event: NSEvent) {
        let modifiers = ModifierKey.allCases.filter { event.modifierFlags.contains($0.appKitFlag) }
        guard !modifiers.isEmpty else { return nil }
        let label = Self.namedKeys[event.keyCode] ?? event.charactersIgnoringModifiers?.uppercased() ?? "?"
        self.init(keyCode: Int64(event.keyCode), keyLabel: label, modifiers: modifiers)
    }
}

extension ModifierKey {
    var appKitFlag: NSEvent.ModifierFlags {
        switch self {
        case .control: .control
        case .option: .option
        case .shift: .shift
        case .command: .command
        }
    }
}
