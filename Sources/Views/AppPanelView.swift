import SwiftUI

private enum PanelTab: String, CaseIterable {
    case settings = "Settings"
    case info = "About"

    var icon: String {
        switch self {
        case .settings: "gear"
        case .info: "info.circle"
        }
    }
}

private let panelWidth: CGFloat = 320

struct AppPanelView: View {
    let onQuit: () -> Void
    @State private var selectedTab: PanelTab = .settings

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(PanelTab.allCases, id: \.self) { tab in
                    tabButton(tab)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)

            tabContents
        }
        .frame(width: panelWidth)
    }

    /// Every tab stays laid out so the panel keeps one height: the menu bar window glitches when its content resizes.
    private var tabContents: some View {
        ZStack(alignment: .top) {
            tabContent(.settings) { SettingsView(onQuit: onQuit) }
            tabContent(.info) { InfoView(onQuit: onQuit) }
        }
    }

    private func tabContent<Content: View>(_ tab: PanelTab, @ViewBuilder content: () -> Content) -> some View {
        content()
            .opacity(selectedTab == tab ? 1 : 0)
            .offset(y: selectedTab == tab ? 0 : 8)
            .allowsHitTesting(selectedTab == tab)
            .accessibilityHidden(selectedTab != tab)
    }

    private func tabButton(_ tab: PanelTab) -> some View {
        Button {
            withAnimation(.snappy(duration: 0.25)) { selectedTab = tab }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: tab.icon)
                    .font(.system(size: 12, weight: .medium))
                if selectedTab == tab {
                    Text(tab.rawValue)
                        .font(.system(size: 11, weight: .semibold))
                        .lineLimit(1)
                        .fixedSize()
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .background {
                if selectedTab == tab {
                    Capsule().fill(.tint.opacity(0.15))
                }
            }
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .focusEffectDisabled()
        .foregroundStyle(selectedTab == tab ? .primary : .secondary)
    }
}
