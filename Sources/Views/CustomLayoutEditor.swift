import SwiftUI

/// Edits `customLayouts` in the config for one window count: tiles dragged on a screen-shaped canvas.
struct CustomLayoutEditor: View {
    @ObservedObject private var configStore = ConfigStore.shared
    let windowCount: Int
    @State private var draftRects: [UnitRect]?
    @State private var dragStartRects: [UnitRect]?
    @State private var activeIndex: Int?

    private static let snapStep = 0.05

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            LayoutCanvas { size in
                ForEach(Array(rects.enumerated()), id: \.offset) { index, rect in
                    editableTile(index: index, rect: rect, canvasSize: size)
                }
            }

            HStack(spacing: 4) {
                Spacer(minLength: 0)
                Text("Copy")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                ForEach(Self.modesToCopyFrom, id: \.self) { mode in
                    Pill(label: mode.label, isOn: false) { copyLayout(from: mode) }
                        .help("Replace this layout with the \(mode.label) one")
                }
            }
        }
    }

    private var savedRects: [UnitRect] {
        let saved = configStore.config.customLayouts[TilingLayouts.customLayoutKey(windowCount)] ?? []
        return saved.count == windowCount ? saved : TilingLayouts.evenGrid(windowCount)
    }

    private var rects: [UnitRect] { draftRects ?? savedRects }

    private func editableTile(index: Int, rect: UnitRect, canvasSize: CGSize) -> some View {
        TileShape(number: index + 1, isActive: activeIndex == index)
            .frame(width: rect.width * canvasSize.width, height: rect.height * canvasSize.height)
            .overlay(alignment: .bottomTrailing) {
                ResizeHandle()
                    .gesture(dragGesture(index: index, canvasSize: canvasSize, resizes: true))
            }
            .offset(x: rect.x * canvasSize.width, y: rect.y * canvasSize.height)
            .gesture(dragGesture(index: index, canvasSize: canvasSize, resizes: false))
            .zIndex(activeIndex == index ? 1 : 0)
    }

    private func dragGesture(index: Int, canvasSize: CGSize, resizes: Bool) -> some Gesture {
        DragGesture(minimumDistance: 1, coordinateSpace: .global)
            .onChanged { value in
                let start = dragStartRects ?? rects
                if dragStartRects == nil { dragStartRects = start }
                activeIndex = index
                let dx = value.translation.width / canvasSize.width
                let dy = value.translation.height / canvasSize.height
                var next = start
                next[index] = resizes ? Self.resized(start[index], dx: dx, dy: dy) : Self.moved(start[index], dx: dx, dy: dy)
                draftRects = next
            }
            .onEnded { _ in
                if let draftRects { save(draftRects) }
                draftRects = nil
                dragStartRects = nil
                activeIndex = nil
            }
    }

    private static func moved(_ rect: UnitRect, dx: Double, dy: Double) -> UnitRect {
        UnitRect(x: snapped(rect.x + dx), y: snapped(rect.y + dy), width: rect.width, height: rect.height).clampedToUnitSquare()
    }

    private static func resized(_ rect: UnitRect, dx: Double, dy: Double) -> UnitRect {
        let maxX = min(snapped(rect.x + rect.width + dx), 1)
        let maxY = min(snapped(rect.y + rect.height + dy), 1)
        return UnitRect(x: rect.x, y: rect.y, width: maxX - rect.x, height: maxY - rect.y).clampedToUnitSquare()
    }

    private static func snapped(_ value: Double) -> Double {
        (value / snapStep).rounded() * snapStep
    }

    private func save(_ rects: [UnitRect]) {
        let key = TilingLayouts.customLayoutKey(windowCount)
        configStore.update { $0.customLayouts[key] = rects }
    }

    private static let modesToCopyFrom = TilingMode.allCases.filter { $0 != .custom && $0 != .off }

    private func copyLayout(from mode: TilingMode) {
        save(TilingLayouts.unitRects(for: windowCount, mode: mode, customLayouts: [:]))
    }
}

private struct ResizeHandle: View {
    var body: some View {
        Image(systemName: "arrow.up.left.and.arrow.down.right")
            .font(.system(size: 8, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 14, height: 14)
            .background(Circle().fill(Color.accentColor))
            .padding(4)
            .contentShape(Rectangle())
    }
}
