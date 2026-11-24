import AppKit
import QuartzCore

/// Click-through, non-activating frame drawn around a window or a stage. It must never take focus.
@MainActor
final class HighlightOverlay {
    private static let padding: CGFloat = 6
    private static let moveDuration: TimeInterval = 0.18
    private static let fadeDuration: TimeInterval = 0.15
    private static let flashHoldDuration: TimeInterval = 0.35

    private lazy var panel = makePanel()
    private var visibilityGeneration = 0

    func show(around rect: CGRect) {
        visibilityGeneration += 1
        let target = rect.convertedToAppKit.insetBy(dx: -Self.padding, dy: -Self.padding)

        if panel.isVisible {
            animate(duration: Self.moveDuration) { self.panel.animator().setFrame(target, display: true) }
            animate(duration: Self.fadeDuration) { self.panel.animator().alphaValue = 1 }
        } else {
            panel.setFrame(target, display: true)
            panel.alphaValue = 0
            panel.orderFrontRegardless()
            animate(duration: Self.fadeDuration) { self.panel.animator().alphaValue = 1 }
        }
    }

    func flash(around rect: CGRect) {
        show(around: rect)
        let generation = visibilityGeneration
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.flashHoldDuration) { [weak self] in
            guard let self, self.visibilityGeneration == generation else { return }
            self.hide()
        }
    }

    func hide() {
        visibilityGeneration += 1
        let generation = visibilityGeneration
        animate(duration: Self.fadeDuration) {
            self.panel.animator().alphaValue = 0
        } completion: { [weak self] in
            guard let self, self.visibilityGeneration == generation else { return }
            self.panel.orderOut(nil)
        }
    }

    private func animate(duration: TimeInterval, _ changes: @escaping () -> Void, completion: (@MainActor () -> Void)? = nil) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = duration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            changes()
        } completionHandler: {
            guard let completion else { return }
            MainActor.assumeIsolated { completion() }
        }
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: true)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .popUpMenu
        panel.ignoresMouseEvents = true
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        panel.contentView = HighlightFrameView()
        return panel
    }
}

private final class HighlightFrameView: NSView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        autoresizingMask = [.width, .height]
    }

    required init?(coder: NSCoder) { nil }

    override func updateLayer() {
        guard let layer else { return }
        let accent = NSColor.controlAccentColor
        layer.cornerRadius = 16
        layer.borderWidth = 3
        layer.borderColor = accent.cgColor
        layer.backgroundColor = accent.withAlphaComponent(0.12).cgColor
    }

    override var wantsUpdateLayer: Bool { true }
}
