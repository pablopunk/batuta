import SwiftUI

/// Click, then press the new keys. Esc or Delete clears an optional shortcut; click again to cancel.
/// The global tap lets keys through while this records.
struct ShortcutRecorder: View {
    @Binding var shortcut: KeyShortcut?
    let owner: ShortcutOwner
    var canClear = false
    @State private var isRecording = false
    @State private var takenBy: String?
    @State private var monitor: Any?

    var body: some View {
        Button(action: toggleRecording) {
            Text(label)
                .foregroundStyle(shortcut == nil && !isRecording ? .secondary : .primary)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(isRecording ? Color.accentColor.opacity(0.3) : Color.secondary.opacity(0.15)))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .focusEffectDisabled()
        .help(canClear ? "Click and press a new shortcut, or Esc to clear it" : "Click and press a new shortcut")
        .onDisappear(perform: stopRecording)
    }

    private var label: String {
        guard isRecording else { return shortcut?.label ?? "None" }
        return takenBy.map { "Used by \($0)" } ?? "Press keys…"
    }

    private func toggleRecording() {
        isRecording ? stopRecording() : startRecording()
    }

    private static let escapeKeyCode: UInt16 = 53
    private static let clearingKeyCodes: Set<UInt16> = [escapeKeyCode, 51, 117]

    private func startRecording() {
        ShortcutRecording.stopOtherRecorder?()
        ShortcutRecording.stopOtherRecorder = stopRecording
        isRecording = true
        takenBy = nil
        ShortcutRecording.isActive = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if canClear, Self.clearingKeyCodes.contains(event.keyCode) {
                shortcut = nil
                stopRecording()
            } else if event.keyCode == Self.escapeKeyCode {
                stopRecording()
            } else if let recorded = KeyShortcut(recording: event) {
                if let action = ShortcutConflicts.actionUsing(recorded, apartFrom: owner) {
                    takenBy = action
                } else {
                    shortcut = recorded
                    stopRecording()
                }
            }
            return nil
        }
    }

    private func stopRecording() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        guard isRecording else { return }
        isRecording = false
        ShortcutRecording.isActive = false
        ShortcutRecording.stopOtherRecorder = nil
    }
}

@MainActor
enum ShortcutRecording {
    static var isActive = false
    /// Only one recorder listens at a time, so starting one stops the other.
    static var stopOtherRecorder: (() -> Void)?
}
