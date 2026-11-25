import SwiftUI

struct SettingsView: View {
    @ObservedObject private var configStore = ConfigStore.shared
    @State private var hasAccessibilityPermission = AccessibilityPermission.isGranted
    @State private var isStageManagerEnabled = StageStrip.isStageManagerEnabled
    let onQuit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                SectionHeaderView(title: "Preferences", icon: "slider.horizontal.3")
                LaunchAtLoginRow()
                PreferenceToggleRow(
                    title: "Show menu bar icon",
                    subtitle: "Reopen app to re-enable",
                    icon: "menubar.rectangle",
                    isOn: configStore.binding(\.showMenuBarIcon)
                )
            }

            Divider().opacity(0.5)

            VStack(alignment: .leading, spacing: 10) {
                SectionHeaderView(title: "Keys", icon: "keyboard")
                ModifierPickerRow()
                MoveModifierPickerRow()
                DirectionKeysRow()
                StageConfirmModeRow()
            }

            Divider().opacity(0.5)

            VStack(alignment: .leading, spacing: 6) {
                SectionHeaderView(title: "Shortcuts", icon: "command")
                ShortcutList()
            }

            Divider().opacity(0.5)

            VStack(alignment: .leading, spacing: 6) {
                SectionHeaderView(title: "Windows", icon: "macwindow")
                PreferenceToggleRow(
                    title: "Highlight focused window",
                    subtitle: "Flash a frame around it",
                    icon: "sparkles",
                    isOn: configStore.binding(\.highlightFocusedWindow)
                )
                PreferenceToggleRow(
                    title: "Animate window moves",
                    subtitle: "Off snaps windows into place",
                    icon: "wind",
                    isOn: configStore.binding(\.animateWindowMoves)
                )

                if !hasAccessibilityPermission {
                    WarningButton(title: "Accessibility permissions needed", action: AccessibilityPermission.openSettings)
                }
                if !isStageManagerEnabled {
                    WarningButton(title: "Stage Manager is off", action: AccessibilityPermission.openStageManagerSettings)
                }
            }

            Divider().opacity(0.5)

            Button(action: onQuit) {
                HStack(spacing: 4) {
                    Image(systemName: "power")
                    Text("Quit")
                    Text("⌘Q")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(14)
        .onAppear(perform: refreshWarnings)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            refreshWarnings()
        }
    }

    private func refreshWarnings() {
        hasAccessibilityPermission = AccessibilityPermission.isGranted
        isStageManagerEnabled = StageStrip.isStageManagerEnabled
    }
}

private struct ModifierPickerRow: View {
    @ObservedObject private var configStore = ConfigStore.shared

    var body: some View {
        CaptionedRow(
            title: "Navigate",
            icon: "command",
            caption: "Hold to move between windows and stages."
        ) {
            HStack(spacing: 4) {
                ForEach(ModifierKey.allCases, id: \.self) { key in
                    Pill(label: key.symbol, isOn: configStore.config.modifiers.contains(key), isLocked: key == configStore.config.moveModifier) {
                        configStore.update { $0 = $0.toggling(key) }
                    }
                }
            }
        }
    }

}

private struct MoveModifierPickerRow: View {
    @ObservedObject private var configStore = ConfigStore.shared

    var body: some View {
        CaptionedRow(
            title: "Move",
            icon: "arrow.left.and.right.square",
            caption: "Moves windows instead of focusing them."
        ) {
            HStack(spacing: 4) {
                ForEach(ModifierKey.allCases, id: \.self) { key in
                    let isNavigateKey = configStore.config.modifiers.contains(key)
                    Pill(label: key.symbol, isOn: isNavigateKey || configStore.config.moveModifier == key, isLocked: isNavigateKey) {
                        configStore.update { $0 = $0.choosingMoveModifier(key) }
                    }
                }
            }
        }
    }
}

private struct DirectionKeysRow: View {
    @ObservedObject private var configStore = ConfigStore.shared

    var body: some View {
        HStack(spacing: 10) {
            RowIcon(systemName: "arrow.up.and.down.and.arrow.left.and.right")
            Text("Keys")
                .font(.system(size: 13, weight: .medium))
            Spacer(minLength: 0)
            HStack(spacing: 4) {
                ForEach(DirectionKeys.allCases, id: \.self) { keys in
                    Pill(label: keys.label, isOn: configStore.config.directionKeys == keys) {
                        configStore.update { $0.directionKeys = keys }
                    }
                }
            }
        }
        .frame(minHeight: 28)
    }
}

private struct StageConfirmModeRow: View {
    @ObservedObject private var configStore = ConfigStore.shared
    private var confirmMode: StageConfirmMode { configStore.config.openStageOn }

    var body: some View {
        CaptionedRow(title: "Open stage", icon: "checkmark.circle", caption: caption) {
            HStack(spacing: 4) {
                Pill(label: "Release", isOn: confirmMode == .releaseModifier) { configStore.update { $0.openStageOn = .releaseModifier } }
                Pill(label: "↩", isOn: confirmMode == .pressReturn) { configStore.update { $0.openStageOn = .pressReturn } }
            }
        }
    }

    private var caption: String {
        switch confirmMode {
        case .releaseModifier: "Opens when you let go. Esc cancels."
        case .pressReturn: "Opens on ↩. Esc cancels."
        }
    }
}

struct ConfigFileButton: View {
    var body: some View {
        Button {
            NSWorkspace.shared.activateFileViewerSelecting([ConfigStore.fileURL])
        } label: {
            Label("~/.config/batuta/config.json", systemImage: "doc.text")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .help("Reveal the config file in Finder")
    }
}

/// A quiet cheat sheet: what each shortcut does, with the keys from the current config.
private struct ShortcutList: View {
    @ObservedObject private var configStore = ConfigStore.shared

    var body: some View {
        VStack(spacing: 5) {
            row("Focus window", navigate, keys.leftRightLabel)
            row("Move window", move, keys.leftRightLabel)
            row("Pick a stage", navigate, keys.upDownLabel)
            row("Jump to stage", navigate, "1–9")
            row("Resize window", navigate, "+ −")
            if let cycleShortcut { row("Cycle tiling mode", symbols(cycleShortcut.modifiers), cycleShortcut.keyLabel) }
            ForEach(TilingMode.allCases.filter { config.shortcut(toggling: $0) != nil }, id: \.self) { mode in
                let shortcut = config.shortcut(toggling: mode)!
                row("Toggle \(mode.label)", symbols(shortcut.modifiers), shortcut.keyLabel)
            }
        }
        .padding(.leading, 28)
    }

    private var config: BatutaConfig { configStore.config }
    private var keys: DirectionKeys { config.directionKeys }
    private var cycleShortcut: KeyShortcut? { config.effectiveCycleTilingModeShortcut }
    private var navigate: String { symbols(config.modifiers) }
    private var move: String { symbols(config.modifiers + [config.moveModifier]) }

    private func symbols(_ modifiers: [ModifierKey]) -> String {
        ModifierKey.allCases.filter(modifiers.contains).map(\.symbol).joined()
    }

    private func row(_ title: String, _ modifiers: String, _ key: String) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Spacer(minLength: 4)
            KeyHint(modifiers: modifiers, key: key)
        }
    }
}

/// Modifiers and key sit in fixed columns so every hint in a list lines up.
struct KeyHint: View {
    let modifiers: String
    let key: String

    var body: some View {
        HStack(spacing: 6) {
            Text(modifiers)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .tracking(1.5)
                .frame(width: 56, alignment: .trailing)
            Text(key)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .frame(width: 30, alignment: .leading)
        }
        .lineLimit(1)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(Color.secondary.opacity(0.15)))
    }
}
