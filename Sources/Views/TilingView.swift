import SwiftUI

private enum ScreenKind: String, CaseIterable {
    case laptop = "Laptop"
    case external = "External"

    /// The screen where you clicked the menu bar icon.
    static var underMouse: ScreenKind {
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) } ?? NSScreen.main
        return screen?.isBuiltIn ?? true ? .laptop : .external
    }
}

struct TilingView: View {
    @ObservedObject private var configStore = ConfigStore.shared
    @ObservedObject private var appSizeStore = AppSizeStore.shared
    @State private var windowCount = 2
    @State private var screenKind: ScreenKind = .laptop

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                SectionHeaderView(title: "Tiling", icon: "square.grid.2x2")
                Spacer(minLength: 0)
                HStack(spacing: 4) {
                    ForEach(ScreenKind.allCases, id: \.self) { kind in
                        Pill(label: kind.rawValue, isOn: screenKind == kind) { screenKind = kind }
                    }
                }
            }

            if screenKind == .external {
                PreferenceToggleRow(
                    title: "Own settings",
                    subtitle: "Off uses the Laptop settings",
                    icon: "display",
                    isOn: configStore.binding(\.externalScreensHaveOwnTiling)
                )
            }

            Group {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        ForEach(TilingMode.allCases, id: \.self) { mode in
                            Pill(label: mode.label, isOn: settings.mode == mode) {
                                updateSettings { $0.mode = mode }
                            }
                        }
                    }
                    .fixedSize()
                    .frame(maxWidth: .infinity)
                    Text("Default for every stage. " + modeCaption)
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                PreferenceToggleRow(
                    title: "Don't cover Stage Manager",
                    subtitle: "Tile beside the thumbnails",
                    icon: "sidebar.left",
                    isOn: Binding(get: { settings.leaveRoomForStageManager }, set: { isOn in updateSettings { $0.leaveRoomForStageManager = isOn } })
                )

                PreferenceToggleRow(
                    title: "Learn app size",
                    subtitle: "For 1-window stages",
                    icon: "macwindow",
                    isOn: Binding(get: { settings.rememberAppSizes }, set: { isOn in updateSettings { $0.rememberAppSizes = isOn } })
                )
            }
            .disabled(!isEditable)
            .opacity(isEditable ? 1 : 0.45)

            PreferenceToggleRow(
                title: "Tile on stage switch",
                subtitle: "Also when you click a stage",
                icon: "rectangle.stack",
                isOn: configStore.binding(\.tileWhenSwitchingStages)
            )

            CycleShortcutRow()

            ModeShortcutRows()

            if settings.rememberAppSizes && !appSizesForThisTab.isEmpty {
                AppSizeRows(appSizes: appSizesForThisTab) { bundleID in
                    appSizeStore.set(nil, for: bundleID, onBuiltInScreen: !editsExternalSettings)
                }
                    .disabled(!isEditable)
                    .opacity(isEditable ? 1 : 0.45)
            }

            if settings.mode != .off { WindowCountStepper(count: $windowCount) }

            if settings.mode == .custom {
                if isEditable {
                    CustomLayoutEditor(windowCount: windowCount, layouts: settings.customLayouts) { key, rects in updateSettings { $0.customLayouts[key] = rects } }
                        .id("\(editsExternalSettings)-\(windowCount)")
                } else {
                    LayoutPreview(rects: previewRects).opacity(0.45)
                }
            } else if settings.mode != .off {
                LayoutPreview(rects: previewRects)
            }
        }
        .padding(14)
        .onAppear { screenKind = ScreenKind.underMouse }
    }

    private var appSizesForThisTab: [String: UnitRect] {
        appSizeStore.sizes(onBuiltInScreen: !editsExternalSettings)
    }

    private var editsExternalSettings: Bool {
        screenKind == .external && configStore.config.externalScreensHaveOwnTiling
    }

    private var isEditable: Bool {
        screenKind == .laptop || configStore.config.externalScreensHaveOwnTiling
    }

    private var settings: TilingSettings {
        editsExternalSettings ? configStore.config.externalTiling : configStore.config.tiling
    }

    private func updateSettings(_ change: @escaping (inout TilingSettings) -> Void) {
        let editsExternal = editsExternalSettings
        configStore.update { config in
            if editsExternal { change(&config.externalTiling) } else { change(&config.tiling) }
        }
    }

    private var previewRects: [UnitRect] {
        TilingLayouts.unitRects(for: windowCount, mode: settings.mode, customLayouts: settings.customLayouts)
    }

    private var modeCaption: String {
        switch settings.mode {
        case .off: "Batuta leaves windows where they are. The shortcut can still tile one stage."
        case .even: "Every window gets the same space, in rows."
        case .bsp: "Each new window splits the last one in half."
        case .messy: "Loose layouts where windows can overlap."
        case .custom: "Draw where windows go for 1 to 6 windows. Drag to move, drag the corner to resize. Tile 1 is the leftmost window."
        }
    }
}

private struct CycleShortcutRow: View {
    @ObservedObject private var configStore = ConfigStore.shared

    var body: some View {
        CaptionedRow(
            title: "Cycle mode",
            icon: "arrow.triangle.2.circlepath",
            caption: "Changes the mode of the current stage only. Other stages keep the default. Click the shortcut to change it, or press Esc to clear it."
        ) {
            ShortcutRecorder(shortcut: configStore.binding(\.effectiveCycleTilingModeShortcut), owner: .cycleMode, canClear: true)
        }
    }
}

private struct AppSizeRows: View {
    let appSizes: [String: UnitRect]
    let forget: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 10) {
                RowIcon(systemName: "macwindow")
                Text("App sizes")
                    .font(.system(size: 13, weight: .medium))
            }
            Text("Where a lone window goes in Messy and Custom, learned when you move or resize it.")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, 28)
            VStack(spacing: 4) {
                ForEach(sortedBundleIDs, id: \.self) { bundleID in
                    HStack {
                        Text(AppSizes.appName(for: bundleID))
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        Spacer(minLength: 0)
                        Button { forget(bundleID) } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.tertiary)
                        }
                        .buttonStyle(.plain)
                        .help("Forget this size")
                    }
                }
            }
            .padding(.leading, 28)
            .padding(.top, 2)
        }
    }

    private var sortedBundleIDs: [String] {
        appSizes.keys.sorted { AppSizes.appName(for: $0) < AppSizes.appName(for: $1) }
    }
}

private struct ModeShortcutRows: View {
    @ObservedObject private var configStore = ConfigStore.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 10) {
                RowIcon(systemName: "keyboard")
                Text("Mode shortcuts")
                    .font(.system(size: 13, weight: .medium))
            }
            Text("Sets that mode on the current stage. Press it again to go back. Esc clears a shortcut.")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, 28)
            VStack(spacing: 4) {
                ForEach(TilingMode.allCases, id: \.self) { mode in
                    HStack {
                        Text(mode.label)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        Spacer(minLength: 0)
                        ShortcutRecorder(shortcut: binding(for: mode), owner: .mode(mode), canClear: true)
                    }
                }
            }
            .padding(.leading, 28)
            .padding(.top, 2)
        }
    }

    private func binding(for mode: TilingMode) -> Binding<KeyShortcut?> {
        Binding(
            get: { configStore.config.shortcut(toggling: mode) },
            set: { shortcut in configStore.update { $0.modeShortcuts[mode.rawValue] = shortcut } }
        )
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
