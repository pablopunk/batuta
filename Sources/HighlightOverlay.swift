import AppKit
import QuartzCore

/// Click-through, non-activating frame drawn around a window or a stage. It must never take focus.
/// The panel covers the whole screen and only a Core Animation layer moves, because resizing a window every frame is slow.
@MainActor
final class HighlightOverlay {
    private static let padding: CGFloat = 6
    private static let moveDuration: CFTimeInterval = 0.16
    private static let fadeDuration: CFTimeInterval = 0.12
    private static let flashHoldDuration: TimeInterval = 0.35
    private static let ignoredMoveDistance: CGFloat = 1.5

    private lazy var panel = makePanel()
    private let frameLayer = makeFrameLayer()
    private var visibilityGeneration = 0
    private var isShown = false

    func show(around rect: CGRect) {
        visibilityGeneration += 1
        let target = rect.convertedToAppKit.insetBy(dx: -Self.padding, dy: -Self.padding)
        guard let screen = NSScreen.screens.first(where: { $0.frame.intersects(target) }) ?? NSScreen.main else { return }

        let movesToAnotherScreen = panel.frame != screen.frame
        if movesToAnotherScreen { panel.setFrame(screen.frame, display: false) }
        let layerFrame = target.offsetBy(dx: -screen.frame.minX, dy: -screen.frame.minY)

        if isShown && !movesToAnotherScreen {
            move(to: layerFrame)
        } else {
            place(at: layerFrame)
        }
        fade(to: 1)
        if !panel.isVisible { panel.orderFrontRegardless() }
        isShown = true
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
        isShown = false
        fade(to: 0)
    }

    private func place(at frame: CGRect) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        frameLayer.removeAnimation(forKey: "frame")
        frameLayer.frame = frame
        CATransaction.commit()
    }

    /// Starts from where the layer is on screen right now, so a new target mid-move keeps the motion smooth.
    private func move(to frame: CGRect) {
        let current = frameLayer.presentation()?.frame ?? frameLayer.frame
        guard abs(current.minX - frame.minX) > Self.ignoredMoveDistance
            || abs(current.minY - frame.minY) > Self.ignoredMoveDistance
            || abs(current.width - frame.width) > Self.ignoredMoveDistance
            || abs(current.height - frame.height) > Self.ignoredMoveDistance
        else { return }

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        frameLayer.frame = frame
        CATransaction.commit()

        let animation = CAAnimationGroup()
        let position = CABasicAnimation(keyPath: "position")
        position.fromValue = NSValue(point: CGPoint(x: current.midX, y: current.midY))
        let bounds = CABasicAnimation(keyPath: "bounds")
        bounds.fromValue = NSValue(rect: CGRect(origin: .zero, size: current.size))
        animation.animations = [position, bounds]
        animation.duration = Self.moveDuration
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        frameLayer.add(animation, forKey: "frame")
    }

    private func fade(to opacity: Float) {
        let current = frameLayer.presentation()?.opacity ?? frameLayer.opacity
        guard current != opacity || frameLayer.opacity != opacity else { return }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        frameLayer.opacity = opacity
        CATransaction.commit()
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = current
        animation.duration = Self.fadeDuration
        frameLayer.add(animation, forKey: "opacity")
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
        let contentView = NSView()
        contentView.wantsLayer = true
        contentView.layer?.addSublayer(frameLayer)
        panel.contentView = contentView
        return panel
    }

    private static func makeFrameLayer() -> CALayer {
        let layer = CALayer()
        let accent = NSColor.controlAccentColor
        layer.cornerRadius = 16
        layer.borderWidth = 3
        layer.borderColor = accent.cgColor
        layer.backgroundColor = accent.withAlphaComponent(0.12).cgColor
        layer.opacity = 0
        return layer
    }
}
