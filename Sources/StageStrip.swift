import AppKit
import os
import ApplicationServices

struct StageStripItem {
    let element: AXUIElement
    let title: String
    let frame: CGRect
}

struct StageStrip {
    static let windowManagerBundleID = "com.apple.WindowManager"
    private static let stripIdentifier = "sm.strip"

    let items: [StageStripItem]
    let isOnLeftEdge: Bool

    static var isStageManagerEnabled: Bool {
        UserDefaults(suiteName: windowManagerBundleID)?.bool(forKey: "GloballyEnabled") ?? false
    }

    @MainActor
    static func closest(to reference: CGRect?) -> StageStrip? {
        guard let windowManager = NSRunningApplication.runningApplications(withBundleIdentifier: windowManagerBundleID).first else {
            return nil
        }

        let strips = AXUIElementCreateApplication(windowManager.processIdentifier)
            .descendants(withIdentifier: stripIdentifier, maxDepth: 3)
            .compactMap { strip in strip.frame.map { (element: strip, frame: $0) } }

        let referenceMidX = reference?.midX ?? 0
        guard let strip = strips.min(by: { abs($0.frame.midX - referenceMidX) < abs($1.frame.midX - referenceMidX) }) else {
            return nil
        }

        let items = strip.element.children
            .filter { $0.role == kAXButtonRole }
            .compactMap { button in button.frame.map { StageStripItem(element: button, title: button.title ?? "", frame: $0) } }
            .sorted { $0.frame.minY < $1.frame.minY }

        return StageStrip(items: items, isOnLeftEdge: isOnLeftHalfOfItsScreen(strip.frame))
    }

    private static let log = Logger(subsystem: "com.pablopunk.batuta", category: "stage")

    static func open(_ item: StageStripItem) {
        let opened = item.element.perform(kAXPressAction)
        log.info("open stage \(item.title, privacy: .public): \(opened ? "ok" : "failed", privacy: .public)")
    }

    @MainActor
    private static func isOnLeftHalfOfItsScreen(_ frame: CGRect) -> Bool {
        let appKitFrame = frame.convertedToAppKit
        let screen = NSScreen.screens.first { $0.frame.intersects(appKitFrame) } ?? NSScreen.main
        return appKitFrame.midX < (screen?.frame.midX ?? .greatestFiniteMagnitude)
    }
}
