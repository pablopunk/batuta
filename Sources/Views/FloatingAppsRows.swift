import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// Apps whose windows always float. Dialogs and fixed-size windows of any app float on their own.
struct FloatingAppsRows: View {
    @ObservedObject private var configStore = ConfigStore.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 10) {
                RowIcon(systemName: "square.on.square")
                Text("Floating apps")
                    .font(.system(size: 13, weight: .medium))
                Spacer(minLength: 0)
                Button("Add App…", action: addApp)
                    .controlSize(.small)
            }
            Text("Batuta never tiles these apps. Dialogs and windows that cannot resize always float.")
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
                        Button { remove(bundleID) } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.tertiary)
                        }
                        .buttonStyle(.plain)
                        .help("Tile this app again")
                    }
                }
            }
            .padding(.leading, 28)
            .padding(.top, 2)
        }
    }

    private var sortedBundleIDs: [String] {
        configStore.config.floatingApps.sorted { AppSizes.appName(for: $0) < AppSizes.appName(for: $1) }
    }

    private func remove(_ bundleID: String) {
        configStore.update { $0.floatingApps.removeAll { $0 == bundleID } }
    }

    private func addApp() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowsMultipleSelection = true
        guard panel.runModal() == .OK else { return }
        let bundleIDs = panel.urls.compactMap { Bundle(url: $0)?.bundleIdentifier }
        configStore.update { config in
            config.floatingApps += bundleIDs.filter { !config.floatingApps.contains($0) }
        }
    }
}
