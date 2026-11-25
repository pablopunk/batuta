import SwiftUI

/// Click, then press the new keys. Esc cancels, and Delete clears an optional shortcut.
/// The global tap lets keys through while this records.
struct ShortcutRecorder: View {
    @Binding var shortcut: KeyShortcut?
    var canClear = false
    @State private var isRecording = false
    @State private var monitor: Any?

    var body: some View {
        Button(action: toggleRecording) {
            Text(isRecording ? "Press keys…" : shortcut?.label ?? "None")
                .foregroundStyle(shortcut == nil && !isRecording ? .secondary : .primary)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(isRecording ? Color.accentColor.opacity(0.3) : Color.secondary.opacity(0.15)))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .focusEffectDisabled()
        .help(canClear ? "Click and press a new shortcut, or Delete to clear it" : "Click and press a new shortcut")
        .onDisappear(perform: stopRecording)
    }

    private func toggleRecording() {
        isRecording ? stopRecording() : startRecording()
    }

    private func startRecording() {
        isRecording = true
        ShortcutRecording.isActive = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 {
                stopRecording()
            } else if canClear, event.keyCode == 51 || event.keyCode == 117 {
                shortcut = nil
                stopRecording()
            } else if let recorded = KeyShortcut(recording: event) {
                shortcut = recorded
                stopRecording()
            }
            return nil
        }
    }

    private func stopRecording() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        isRecording = false
        ShortcutRecording.isActive = false
    }
}

@MainActor
enum ShortcutRecording {
    static var isActive = false
}
