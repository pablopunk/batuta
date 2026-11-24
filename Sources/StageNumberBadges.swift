import AppKit

/// Click-through numbers drawn on the Stage Manager thumbnails while the navigate keys are held, for Navigate + number.
@MainActor
final class StageNumberBadges {
    private static let size: CGFloat = 22
    private lazy var panel = makePanel()

    func show(on items: [StageStripItem]) {
        guard let first = items.first,
              let screen = NSScreen.screens.first(where: { $0.frame.intersects(first.frame.convertedToAppKit) }) ?? NSScreen.main else { return }
        panel.setFrame(screen.frame, display: false)
        let contentView = panel.contentView!
        contentView.subviews.forEach { $0.removeFromSuperview() }
        for (index, item) in items.prefix(9).enumerated() {
            let appKitFrame = item.frame.convertedToAppKit.offsetBy(dx: -screen.frame.minX, dy: -screen.frame.minY)
            let origin = CGPoint(x: appKitFrame.minX + 2, y: appKitFrame.maxY - Self.size - 2)
            contentView.addSubview(makeBadge(number: index + 1, at: origin))
        }
        panel.orderFrontRegardless()
    }

    func hide() {
        panel.orderOut(nil)
    }

    private func makeBadge(number: Int, at origin: CGPoint) -> NSView {
        let badge = NSView(frame: CGRect(origin: origin, size: CGSize(width: Self.size, height: Self.size)))
        badge.wantsLayer = true
        badge.layer?.backgroundColor = NSColor.controlAccentColor.cgColor
        badge.layer?.cornerRadius = Self.size / 2
        let label = NSTextField(labelWithString: "\(number)")
        label.font = .systemFont(ofSize: 12, weight: .bold)
        label.textColor = .white
        label.alignment = .center
        label.sizeToFit()
        label.frame = CGRect(x: 0, y: (Self.size - label.frame.height) / 2, width: Self.size, height: label.frame.height)
        badge.addSubview(label)
        return badge
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
        panel.contentView = NSView()
        return panel
    }
}
