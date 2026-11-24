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
                SectionHeaderView(title: "Navigation", icon: "arrow.left.arrow.right")
                ModifierPickerRow()
                MoveModifierPickerRow()
                DirectionKeysRow()
                StageConfirmModeRow()
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
                ConfigFileButton()

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
            caption: "Hold it with \(keys.leftRightLabel) to move between windows. Keep going past the edge to reach your stages, then \(keys.upDownLabel)."
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

    private var keys: DirectionKeys { configStore.config.directionKeys }
}

private struct MoveModifierPickerRow: View {
    @ObservedObject private var configStore = ConfigStore.shared

    var body: some View {
        CaptionedRow(
            title: "Move",
            icon: "arrow.left.and.right.square",
            caption: "Add one more key to move instead: swap windows, take one out of the stage, or pull a stage in."
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
        case .releaseModifier: "Let go of the modifier to open the selected stage. Esc cancels."
        case .pressReturn: "Press ↩ to open the selected stage. Esc cancels."
        }
    }
}

private struct ConfigFileButton: View {
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
