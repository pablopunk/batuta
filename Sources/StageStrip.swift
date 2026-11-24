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
    let frame: CGRect
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

        return StageStrip(items: items, frame: strip.frame, isOnLeftEdge: isOnLeftHalfOfItsScreen(strip.frame))
    }

    private static let log = Logger(subsystem: "com.pablopunk.batuta", category: "stage")

    /// AXAddToStage reports success but is ignored too, so the thumbnail is dragged onto the current stage like a person would.
    @MainActor
    static func addToCurrentStage(_ item: StageStripItem, droppingAt stageCenter: CGPoint, completion: @escaping @MainActor () -> Void) {
        SyntheticMouse.drag(from: item.frame.center, to: stageCenter, completion: completion)
        log.info("dragged stage \(item.title, privacy: .public) into current stage")
    }

    /// Stage Manager has no API for this either, so the window is dragged by its title bar onto the strip.
    @MainActor
    static func removeFromCurrentStage(_ window: StageWindow, strip: StageStrip) {
        SyntheticMouse.drag(from: titleBarGrabPoint(of: window), to: strip.frame.center) {}
        log.info("dragged window \(window.id) out of the current stage")
    }

    /// Just right of the zoom button is title bar in most apps, and it avoids the traffic lights.
    @MainActor
    private static func titleBarGrabPoint(of window: StageWindow) -> CGPoint {
        if let zoomButton = window.element.element(kAXZoomButtonAttribute)?.frame {
            return CGPoint(x: zoomButton.maxX + 8, y: zoomButton.midY)
        }
        return CGPoint(x: window.frame.minX + 90, y: window.frame.minY + 14)
    }

    /// AXPress on a strip button reports success but Stage Manager ignores it, so the stage opens by focusing one of its windows instead.
    @MainActor
    static func open(_ item: StageStripItem) {
        guard let window = StageWindows.windowShownAsThumbnail(inside: item.frame) else {
            SyntheticMouse.click(at: item.frame.center)
            log.info("opened stage \(item.title, privacy: .public) by clicking it, no window matched")
            return
        }
        StageWindows.focus(window)
        log.info("opened stage \(item.title, privacy: .public) via window \(window.id)")
    }

    @MainActor
    private static func isOnLeftHalfOfItsScreen(_ frame: CGRect) -> Bool {
        let appKitFrame = frame.convertedToAppKit
        let screen = NSScreen.screens.first { $0.frame.intersects(appKitFrame) } ?? NSScreen.main
        return appKitFrame.midX < (screen?.frame.midX ?? .greatestFiniteMagnitude)
    }
}
