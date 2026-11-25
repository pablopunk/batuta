import AppKit
import SwiftUI

@MainActor
final class OnboardingWindow {
    static let shared = OnboardingWindow()
    private static let finishedKey = "hasFinishedOnboarding"
    private var window: NSWindow?

    static var hasFinished: Bool { UserDefaults.standard.bool(forKey: finishedKey) }

    func show() {
        let window = window ?? makeWindow()
        self.window = window
        window.center()
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    private func finish() {
        UserDefaults.standard.set(true, forKey: Self.finishedKey)
        window?.close()
    }

    private func makeWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: .zero,
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: OnboardingView(onDone: { [weak self] in self?.finish() }))
        return window
    }
}
