import AppKit
import Sparkle

@MainActor
final class AppUpdater: NSObject, @preconcurrency SPUStandardUserDriverDelegate {
    static let shared = AppUpdater()

    private(set) var controller: SPUStandardUpdaterController?
    private var presentedUpdateUI = false

    var updater: SPUUpdater? { controller?.updater }

    var supportsGentleScheduledUpdateReminders: Bool { true }

    override private init() {
        super.init()
    }

    func startIfBundleHasUpdateFeed() {
        guard controller == nil, Bundle.main.hasSparkleUpdateFeed else { return }
        controller = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: self)
    }

    func checkForUpdates() {
        updater?.checkForUpdates()
    }

    func standardUserDriverWillHandleShowingUpdate(_ handleShowingUpdate: Bool, forUpdate update: SUAppcastItem, state: SPUUserUpdateState) {
        guard handleShowingUpdate else { return }
        presentedUpdateUI = true
        NSApp.setActivationPolicy(.regular)
        if !state.userInitiated {
            NSApp.dockTile.badgeLabel = "1"
        }
    }

    func standardUserDriverDidReceiveUserAttention(forUpdate update: SUAppcastItem) {
        NSApp.dockTile.badgeLabel = nil
    }

    func standardUserDriverWillFinishUpdateSession() {
        NSApp.dockTile.badgeLabel = nil
        guard presentedUpdateUI else { return }
        NSApp.setActivationPolicy(.accessory)
        presentedUpdateUI = false
    }
}

private extension Bundle {
    var hasSparkleUpdateFeed: Bool {
        let feedURL = infoDictionary?["SUFeedURL"] as? String ?? ""
        let publicKey = infoDictionary?["SUPublicEDKey"] as? String ?? ""
        return !feedURL.isEmpty && !publicKey.isEmpty
    }
}
