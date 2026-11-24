import AppKit

/// A short click-through label in the middle of the screen that names the tiling mode a stage switched to.
@MainActor
final class ModeBanner {
    private static let holdDuration: TimeInterval = 0.7
    private static let fadeDuration: TimeInterval = 0.15

    private lazy var panel = makePanel()
    private let label = NSTextField(labelWithString: "")
    private var generation = 0

    func show(_ text: String, near rect: CGRect) {
        generation += 1
        let current = generation
        label.stringValue = text
        label.sizeToFit()
        let size = CGSize(width: label.frame.width + 40, height: label.frame.height + 20)
        let appKitRect = rect.convertedToAppKit
        let screen = NSScreen.screens.first { $0.frame.intersects(appKitRect) } ?? NSScreen.main
        let center = screen.map { CGPoint(x: $0.frame.midX, y: $0.frame.midY) } ?? .zero
        panel.setFrame(CGRect(x: center.x - size.width / 2, y: center.y - size.height / 2, width: size.width, height: size.height), display: true)
        label.frame.origin = CGPoint(x: 20, y: 10)
        panel.alphaValue = 1
        panel.orderFrontRegardless()

        DispatchQueue.main.asyncAfter(deadline: .now() + Self.holdDuration) { [weak self] in
            guard let self, current == self.generation else { return }
            NSAnimationContext.runAnimationGroup { $0.duration = Self.fadeDuration; self.panel.animator().alphaValue = 0 }
        }
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: true)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .statusBar
        panel.ignoresMouseEvents = true
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]

        let background = NSVisualEffectView()
        background.material = .hudWindow
        background.state = .active
        background.wantsLayer = true
        background.layer?.cornerRadius = 12
        background.layer?.masksToBounds = true
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .labelColor
        background.addSubview(label)
        panel.contentView = background
        return panel
    }
}
