import AppKit
import ApplicationServices

struct StageWindow {
    let element: AXUIElement
    let pid: pid_t
    let id: CGWindowID
    let frame: CGRect
    var isTileable = true
}

@MainActor
enum StageWindows {
    static func visibleSortedLeftToRight() -> [StageWindow] {
        let onScreen = onScreenNormalWindows()
        let boundsByID = Dictionary(onScreen.map { ($0.id, $0.bounds) }, uniquingKeysWith: { first, _ in first })
        let pids = Set(onScreen.map(\.pid))

        return pids
            .flatMap { pid in standardWindows(of: pid).filter { isShownFullSize($0, bounds: boundsByID[$0.id]) } }
            .sorted { ($0.frame.midX, $0.frame.minY) < ($1.frame.midX, $1.frame.minY) }
    }

    static func windowShownAsThumbnail(inside stripItemFrame: CGRect) -> StageWindow? {
        onScreenNormalWindows()
            .filter { stripItemFrame.contains(CGPoint(x: $0.bounds.midX, y: $0.bounds.midY)) }
            .lazy
            .compactMap { thumbnail in standardWindows(of: thumbnail.pid).first { $0.id == thumbnail.id } }
            .first
    }

    /// Where the small window pictures are drawn inside the strip, which is narrower than the strip buttons.
    static func thumbnailBounds(inside stripItemFrames: [CGRect]) -> CGRect? {
        onScreenNormalWindows()
            .map(\.bounds)
            .filter { bounds in stripItemFrames.contains { $0.contains(CGPoint(x: bounds.midX, y: bounds.midY)) } }
            .reduce(nil) { union, bounds in union?.union(bounds) ?? bounds }
    }

    static func focusedWindowID() -> CGWindowID? {
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        return AXUIElementCreateApplication(app.processIdentifier)
            .element(kAXFocusedWindowAttribute)?
            .windowID
    }

    static func focus(_ window: StageWindow) {
        window.element.set(kAXMainAttribute, to: kCFBooleanTrue)
        window.element.perform(kAXRaiseAction)
        NSRunningApplication(processIdentifier: window.pid)?.activate()
    }

    /// Windows of other stages are still "on screen" for CoreGraphics, but drawn as small thumbnails in the strip.
    private static func isShownFullSize(_ window: StageWindow, bounds: CGRect?) -> Bool {
        guard let bounds else { return false }
        let tolerance: CGFloat = 4
        return abs(bounds.width - window.frame.width) < tolerance && abs(bounds.height - window.frame.height) < tolerance
    }

    private static func onScreenNormalWindows() -> [(id: CGWindowID, pid: pid_t, bounds: CGRect)] {
        let excludedPIDs = Set([getpid()] + stageManagerPIDs())
        let info = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []

        return info.compactMap { window in
            guard window[kCGWindowLayer as String] as? Int == 0,
                  let id = window[kCGWindowNumber as String] as? CGWindowID,
                  let pid = window[kCGWindowOwnerPID as String] as? pid_t,
                  !excludedPIDs.contains(pid),
                  let boundsDictionary = window[kCGWindowBounds as String] as? NSDictionary,
                  let bounds = CGRect(dictionaryRepresentation: boundsDictionary) else {
                return nil
            }
            return (id, pid, bounds)
        }
    }

    private static func standardWindows(of pid: pid_t) -> [StageWindow] {
        let app = AXUIElementCreateApplication(pid)
        return app.windows.compactMap { element in
            guard element.subrole == kAXStandardWindowSubrole,
                  let id = element.windowID,
                  let frame = element.frame else {
                return nil
            }
            return StageWindow(element: element, pid: pid, id: id, frame: frame, isTileable: !element.refusesTiling)
        }
    }

    private static func stageManagerPIDs() -> [pid_t] {
        NSRunningApplication.runningApplications(withBundleIdentifier: StageStrip.windowManagerBundleID).map(\.processIdentifier)
    }
}
