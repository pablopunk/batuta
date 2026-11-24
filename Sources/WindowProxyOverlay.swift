import AppKit
import QuartzCore

/// Full-screen, click-through panel that slides window pictures with Core Animation, which runs at the display's refresh rate.
@MainActor
final class WindowProxyOverlay {
    private static let cornerRadius: CGFloat = 10

    private lazy var panel = makePanel()
    private var screenOriginInTopLeftCoordinates = CGPoint.zero

    func slide(
        _ proxies: [(image: CGImage, from: CGRect, to: CGRect)],
        on screen: NSScreen,
        duration: CFTimeInterval,
        completion: @escaping @MainActor () -> Void
    ) {
        guard let root = panel.contentView?.layer else { return completion() }
        root.sublayers?.forEach { $0.removeFromSuperlayer() }
        panel.setFrame(screen.frame, display: false)
        screenOriginInTopLeftCoordinates = screen.frame.convertedFromAppKit.origin

        let layers = proxies.map { proxy in
            let layer = CALayer()
            layer.contents = proxy.image
            layer.contentsGravity = .resize
            layer.cornerRadius = Self.cornerRadius
            layer.masksToBounds = true
            layer.frame = local(proxy.from)
            root.addSublayer(layer)
            return layer
        }

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        panel.orderFrontRegardless()
        CATransaction.commit()
        CATransaction.flush()

        CATransaction.begin()
        CATransaction.setAnimationDuration(duration)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(controlPoints: 0.2, 0.9, 0.3, 1))
        CATransaction.setCompletionBlock { MainActor.assumeIsolated { completion() } }
        for (layer, proxy) in zip(layers, proxies) { layer.frame = local(proxy.to) }
        CATransaction.commit()
    }

    func hide() {
        panel.orderOut(nil)
        panel.contentView?.layer?.sublayers?.forEach { $0.removeFromSuperlayer() }
    }

    private func local(_ rect: CGRect) -> CGRect {
        rect.offsetBy(dx: -screenOriginInTopLeftCoordinates.x, dy: -screenOriginInTopLeftCoordinates.y)
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: true)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .floating
        panel.ignoresMouseEvents = true
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]

        let view = NSView()
        view.wantsLayer = true
        view.layer?.isGeometryFlipped = true
        panel.contentView = view
        return panel
    }
}
