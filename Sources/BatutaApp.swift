import SwiftUI
import AppKit

@main
struct BatutaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage(SettingsKeys.showMenuBarIcon) private var showMenuBarIcon = true

    var body: some Scene {
        MenuBarExtra(isInserted: $showMenuBarIcon) {
            AppPanelView(onQuit: { NSApplication.shared.terminate(nil) })
        } label: {
            Image(nsImage: .menuBarIcon)
        }
        .menuBarExtraStyle(.window)
        .windowResizability(.contentMinSize)
        .defaultSize(width: 320, height: 250)
    }
}

@MainActor
extension NSImage {
    static let menuBarIcon: NSImage = {
        let image = NSImage(systemSymbolName: "rectangle.leftthird.inset.filled", accessibilityDescription: "Batuta") ?? NSImage()
        image.isTemplate = true
        return image
    }()
}
