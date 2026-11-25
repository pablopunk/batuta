import AppKit
import SwiftUI

/// A click-through bar in the middle of the screen with every tiling mode; the highlight slides from the mode
/// the stage had to the one it switched to.
@MainActor
final class ModeBanner {
    private static let holdDuration: TimeInterval = 0.9
    private static let fadeDuration: TimeInterval = 0.15
    private static let delayBeforeSliding: TimeInterval = 0.05

    private lazy var panel = makePanel()
    private let model = ModeBarModel()
    private var generation = 0

    func show(switchingFrom previousMode: TilingMode, to newMode: TilingMode, near rect: CGRect) {
        generation += 1
        let current = generation
        let wasVisible = panel.isVisible && panel.alphaValue > 0
        if !wasVisible { model.activeMode = previousMode }
        placeInMiddleOfScreen(containing: rect)
        panel.alphaValue = 1
        panel.orderFrontRegardless()

        DispatchQueue.main.asyncAfter(deadline: .now() + (wasVisible ? 0 : Self.delayBeforeSliding)) { [model] in
            withAnimation(.snappy(duration: 0.25)) { model.activeMode = newMode }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.holdDuration) { [weak self] in
            guard let self, current == self.generation else { return }
            NSAnimationContext.runAnimationGroup { $0.duration = Self.fadeDuration; self.panel.animator().alphaValue = 0 }
        }
    }

    private func placeInMiddleOfScreen(containing rect: CGRect) {
        let size = panel.contentView?.fittingSize ?? CGSize(width: 360, height: 48)
        let appKitRect = rect.convertedToAppKit
        let screen = NSScreen.screens.first { $0.frame.intersects(appKitRect) } ?? NSScreen.main
        let center = screen.map { CGPoint(x: $0.frame.midX, y: $0.frame.midY) } ?? .zero
        panel.setFrame(CGRect(x: center.x - size.width / 2, y: center.y - size.height / 2, width: size.width, height: size.height), display: true)
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
        background.layer?.cornerRadius = 14
        background.layer?.masksToBounds = true
        let bar = NSHostingView(rootView: ModeBar(model: model))
        bar.translatesAutoresizingMaskIntoConstraints = false
        background.addSubview(bar)
        NSLayoutConstraint.activate([
            bar.leadingAnchor.constraint(equalTo: background.leadingAnchor),
            bar.trailingAnchor.constraint(equalTo: background.trailingAnchor),
            bar.topAnchor.constraint(equalTo: background.topAnchor),
            bar.bottomAnchor.constraint(equalTo: background.bottomAnchor),
        ])
        panel.contentView = background
        return panel
    }
}

@MainActor
private final class ModeBarModel: ObservableObject {
    @Published var activeMode: TilingMode = .even
}

private struct ModeBar: View {
    @ObservedObject var model: ModeBarModel
    @Namespace private var highlight

    var body: some View {
        HStack(spacing: 4) {
            ForEach(TilingMode.allCases, id: \.self) { mode in
                let isActive = mode == model.activeMode
                Text(mode.label)
                    .font(.system(size: 15, weight: isActive ? .semibold : .medium))
                    .foregroundStyle(isActive ? Color.white : Color.secondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background {
                        if isActive {
                            Capsule().fill(Color.accentColor).matchedGeometryEffect(id: "active", in: highlight)
                        }
                    }
            }
        }
        .padding(8)
        .fixedSize()
    }
}
