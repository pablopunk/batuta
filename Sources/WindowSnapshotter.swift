import AppKit
import ScreenCaptureKit

/// Takes still pictures of windows with ScreenCaptureKit. Needs the Screen Recording permission.
@MainActor
enum WindowSnapshotter {
    static var hasPermission: Bool { CGPreflightScreenCaptureAccess() }

    static func requestPermission() {
        CGRequestScreenCaptureAccess()
    }

    /// Returns nil unless every window could be captured, so callers can fall back as a whole.
    static func snapshots(of windows: [StageWindow]) async -> [CGImage]? {
        guard let content = try? await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true) else { return nil }
        let scale = NSScreen.main?.backingScaleFactor ?? 2

        var images: [CGImage] = []
        for window in windows {
            guard let scWindow = content.windows.first(where: { $0.windowID == window.id }),
                  let image = try? await capture(scWindow, size: window.frame.size, scale: scale) else {
                return nil
            }
            images.append(image)
        }
        return images
    }

    private static func capture(_ window: SCWindow, size: CGSize, scale: CGFloat) async throws -> CGImage {
        let configuration = SCStreamConfiguration()
        configuration.width = Int(size.width * scale)
        configuration.height = Int(size.height * scale)
        configuration.showsCursor = false
        configuration.ignoreShadowsSingleWindow = true
        return try await SCScreenshotManager.captureImage(
            contentFilter: SCContentFilter(desktopIndependentWindow: window),
            configuration: configuration
        )
    }
}
