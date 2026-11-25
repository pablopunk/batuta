import SwiftUI

struct OnboardingView: View {
    let onDone: () -> Void
    @State private var hasAccessibilityPermission = AccessibilityPermission.isGranted
    @State private var isStageManagerEnabled = StageStrip.isStageManagerEnabled
    private let recheckTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            VStack(alignment: .leading, spacing: 8) {
                SectionHeaderView(title: "Setup", icon: "checklist")
                AccessibilityStatusRow(isGranted: hasAccessibilityPermission)
                StageManagerStatusRow(isEnabled: isStageManagerEnabled)
            }

            Divider().opacity(0.5)

            VStack(alignment: .leading, spacing: 10) {
                SectionHeaderView(title: "Keys", icon: "keyboard")
                ModifierPickerRow()
                MoveModifierPickerRow()
            }

            Divider().opacity(0.5)

            LaunchAtLoginRow()

            Button(action: onDone) {
                Text("Done").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
        }
        .padding(20)
        .padding(.top, 12)
        .frame(width: 340)
        .onReceive(recheckTimer) { _ in recheckSetup() }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text("Welcome to Batuta")
                    .font(.system(size: 17, weight: .semibold))
                Text("Move around Stage Manager with your keyboard.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func recheckSetup() {
        hasAccessibilityPermission = AccessibilityPermission.isGranted
        isStageManagerEnabled = StageStrip.isStageManagerEnabled
    }
}

private struct AccessibilityStatusRow: View {
    let isGranted: Bool

    var body: some View {
        SetupStatusRow(
            title: "Accessibility",
            caption: isGranted ? "Batuta can move your windows." : "Needed to read and move windows.",
            status: isGranted ? .done : .missing
        ) {
            if !isGranted {
                Button("Allow") {
                    AccessibilityPermission.prompt()
                    AccessibilityPermission.openSettings()
                }
                .controlSize(.small)
            }
        }
    }
}

private struct StageManagerStatusRow: View {
    let isEnabled: Bool

    var body: some View {
        SetupStatusRow(
            title: "Stage Manager",
            caption: isEnabled ? "Batuta works on top of it." : "Batuta is made for Stage Manager. Without it, Batuta may not work well.",
            status: isEnabled ? .done : .warning
        ) {
            if !isEnabled {
                Button("Settings", action: AccessibilityPermission.openStageManagerSettings)
                    .controlSize(.small)
            }
        }
    }
}

private enum SetupStatus {
    case done, missing, warning

    var symbol: String {
        switch self {
        case .done: "checkmark.circle.fill"
        case .missing: "xmark.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        }
    }

    var color: Color {
        switch self {
        case .done: .green
        case .missing: .red
        case .warning: .orange
        }
    }
}

private struct SetupStatusRow<Action: View>: View {
    let title: String
    let caption: String
    let status: SetupStatus
    @ViewBuilder let action: () -> Action

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: status.symbol)
                .font(.system(size: 15))
                .foregroundStyle(status.color)
                .frame(width: 18)
                .contentTransition(.symbolEffect(.replace))
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                Text(caption)
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            action()
        }
        .animation(.snappy(duration: 0.2), value: status)
    }
}
