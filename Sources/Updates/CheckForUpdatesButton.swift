import Combine
import Sparkle
import SwiftUI

@MainActor
private final class CanCheckForUpdates: ObservableObject {
    @Published var value = false

    init(updater: SPUUpdater?) {
        updater?.publisher(for: \.canCheckForUpdates).assign(to: &$value)
    }
}

struct CheckForUpdatesButton: View {
    @StateObject private var canCheckForUpdates = CanCheckForUpdates(updater: AppUpdater.shared.updater)

    var body: some View {
        Button {
            AppUpdater.shared.checkForUpdates()
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 11))
                Text("Check for updates…")
                    .font(.system(size: 11, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background(.tint.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.plain)
        .disabled(!canCheckForUpdates.value)
    }
}
