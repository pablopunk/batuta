import SwiftUI

struct SettingsView: View {
    @AppStorage(SettingsKeys.showMenuBarIcon) private var showMenuBarIcon = true
    @AppStorage(SettingsKeys.highlightFocusedWindow) private var highlightFocusedWindow = true
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
                    isOn: $showMenuBarIcon
                )
            }

            Divider().opacity(0.5)

            VStack(alignment: .leading, spacing: 10) {
                SectionHeaderView(title: "Navigation", icon: "arrow.left.arrow.right")
                ModifierPickerRow()
                StageConfirmModeRow()
                PreferenceToggleRow(
                    title: "Highlight focused window",
                    subtitle: "Flash a frame around it",
                    icon: "sparkles",
                    isOn: $highlightFocusedWindow
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
    @AppStorage(SettingsKeys.modifierMask) private var modifierMask = ModifierKey.hyperMask

    var body: some View {
        CaptionedRow(
            title: "Modifier",
            icon: "command",
            caption: "Hold it with ← → to move between windows. Keep going past the edge to reach your stages, then ↑ ↓."
        ) {
            HStack(spacing: 4) {
                ForEach(ModifierKey.allCases, id: \.self) { key in
                    Pill(label: key.symbol, isOn: modifierMask & key.rawValue != 0) { toggle(key) }
                }
            }
        }
    }

    private func toggle(_ key: ModifierKey) {
        let toggledMask = modifierMask ^ key.rawValue
        guard toggledMask != 0 else { return }
        modifierMask = toggledMask
    }
}

private struct StageConfirmModeRow: View {
    @AppStorage(SettingsKeys.stageConfirmMode) private var confirmMode = StageConfirmMode.releaseModifier

    var body: some View {
        CaptionedRow(title: "Open stage", icon: "checkmark.circle", caption: caption) {
            HStack(spacing: 4) {
                Pill(label: "Release", isOn: confirmMode == .releaseModifier) { confirmMode = .releaseModifier }
                Pill(label: "↩", isOn: confirmMode == .pressReturn) { confirmMode = .pressReturn }
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
