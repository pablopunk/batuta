import SwiftUI

struct TilingView: View {
    @ObservedObject private var configStore = ConfigStore.shared
    @State private var windowCount = 2

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView(title: "Tiling", icon: "square.grid.2x2")

            CaptionedRow(title: "Mode", icon: "rectangle.split.2x2", caption: modeCaption) {
                HStack(spacing: 4) {
                    ForEach(TilingMode.allCases, id: \.self) { mode in
                        Pill(label: mode.label, isOn: configStore.config.tilingMode == mode) {
                            configStore.update { $0.tilingMode = mode }
                        }
                    }
                }
            }

            PreferenceToggleRow(
                title: "Leave room for the strip",
                subtitle: "Off lets windows cover the stages",
                icon: "sidebar.left",
                isOn: configStore.binding(\.leaveRoomForStrip)
            )

            WindowCountStepper(count: $windowCount)

            if configStore.config.tilingMode == .custom {
                CustomLayoutEditor(windowCount: windowCount)
            } else {
                LayoutPreview(rects: previewRects)
            }
        }
        .padding(14)
    }

    private var previewRects: [UnitRect] {
        TilingLayouts.unitRects(for: windowCount, mode: configStore.config.tilingMode, customLayouts: configStore.config.customLayouts)
    }

    private var modeCaption: String {
        switch configStore.config.tilingMode {
        case .even: "Every window gets the same space, in rows."
        case .bsp: "Each new window splits the last one in half."
        case .messy: "Loose layouts where windows can overlap."
        case .custom: "Draw where windows go for 1 to 6 windows. Drag to move, drag the corner to resize. Tile 1 is the leftmost window."
        }
    }
}

private struct WindowCountStepper: View {
    @Binding var count: Int
    private let range = TilingLayouts.customWindowCounts

    var body: some View {
        HStack(spacing: 8) {
            Text("Windows")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
            stepButton("minus", isEnabled: count > range.lowerBound) { count -= 1 }
            Text("\(count)")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .frame(minWidth: 14)
            stepButton("plus", isEnabled: count < range.upperBound) { count += 1 }
        }
    }

    private func stepButton(_ symbol: String, isEnabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.snappy(duration: 0.2), action)
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 10, weight: .bold))
                .frame(width: 22, height: 22)
                .background(Circle().fill(Color.secondary.opacity(0.15)))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .focusEffectDisabled()
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.35)
    }
}

private struct LayoutPreview: View {
    let rects: [UnitRect]

    var body: some View {
        LayoutCanvas { size in
            ForEach(Array(rects.enumerated()), id: \.offset) { index, rect in
                TileShape(number: index + 1, isActive: false)
                    .frame(width: rect.width * size.width, height: rect.height * size.height)
                    .offset(x: rect.x * size.width, y: rect.y * size.height)
            }
        }
    }
}

/// A screen-shaped area as wide as the panel content; content is placed from its top-left corner.
/// It has a fixed size because the menu bar window gives a GeometryReader almost no room.
struct LayoutCanvas<Content: View>: View {
    @ViewBuilder let content: (CGSize) -> Content
    static var width: CGFloat { 292 }

    private var size: CGSize {
        let aspectRatio: CGFloat = {
            guard let frame = NSScreen.main?.visibleFrame, frame.height > 0 else { return 16 / 10 }
            return frame.width / frame.height
        }()
        return CGSize(width: Self.width, height: (Self.width / aspectRatio).rounded())
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.08))
                .strokeBorder(Color.secondary.opacity(0.2))
            content(size)
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
    }
}

struct TileShape: View {
    let number: Int
    let isActive: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 5)
            .fill(Color.accentColor.opacity(isActive ? 0.45 : 0.25))
            .strokeBorder(Color.accentColor.opacity(0.8), lineWidth: 1)
            .overlay {
                Text("\(number)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            }
            .padding(2)
    }
}
