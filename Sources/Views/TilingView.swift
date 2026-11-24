import SwiftUI

struct TilingView: View {
    @ObservedObject private var configStore = ConfigStore.shared

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

            if configStore.config.tilingMode == .custom {
                CustomLayoutEditor()
            } else {
                LayoutPreview(rects: previewRects)
            }
        }
        .padding(14)
    }

    private var previewRects: [UnitRect] {
        TilingLayouts.unitRects(for: 3, mode: configStore.config.tilingMode, customLayouts: configStore.config.customLayouts)
    }

    private var modeCaption: String {
        switch configStore.config.tilingMode {
        case .even: "Every window gets the same space, in rows."
        case .messy: "Loose layouts where windows can overlap."
        case .custom: "Draw where windows go for 1 to 6 windows. Drag to move, drag the corner to resize."
        }
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
