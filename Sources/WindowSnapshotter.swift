import AppKit
import ScreenCaptureKit

struct WindowPictures {
    let windows: [CGImage]
    let wallpaper: CGImage
}

/// Takes still pictures of windows and of the wallpaper with ScreenCaptureKit. Needs the Screen Recording permission.
@MainActor
enum WindowSnapshotter {
    private static let wallpaperCacheLifetime: TimeInterval = 300
    private static var cachedWallpaper: (displayID: CGDirectDisplayID, image: CGImage, takenAt: Date)?

    static var hasPermission: Bool { CGPreflightScreenCaptureAccess() }

    static func requestPermission() {
        CGRequestScreenCaptureAccess()
    }

    /// Returns nil unless everything could be captured, so callers can fall back as a whole.
    static func pictures(of windows: [StageWindow], on screen: NSScreen) async -> WindowPictures? {
        guard let content = try? await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true),
              let displayID = screen.displayID,
              let display = content.displays.first(where: { $0.displayID == displayID }) else { return nil }
        let scale = screen.backingScaleFactor

        var images: [CGImage] = []
        for window in windows {
            guard let scWindow = content.windows.first(where: { $0.windowID == window.id }),
                  let image = try? await capture(SCContentFilter(desktopIndependentWindow: scWindow), size: window.frame.size, scale: scale) else {
                return nil
            }
            images.append(image)
        }

        guard let wallpaper = await wallpaper(of: display, content: content, scale: scale) else { return nil }
        return WindowPictures(windows: images, wallpaper: wallpaper)
    }

    /// Everything below normal windows: the wallpaper and desktop icons.
    private static func wallpaper(of display: SCDisplay, content: SCShareableContent, scale: CGFloat) async -> CGImage? {
        if let cachedWallpaper, cachedWallpaper.displayID == display.displayID,
           Date().timeIntervalSince(cachedWallpaper.takenAt) < wallpaperCacheLifetime {
            return cachedWallpaper.image
        }
        let desktopWindows = content.windows.filter { $0.windowLayer < 0 }
        let filter = SCContentFilter(display: display, including: desktopWindows)
        guard let image = try? await capture(filter, size: display.frame.size, scale: scale) else { return nil }
        cachedWallpaper = (display.displayID, image, Date())
        return image
    }

    private static func capture(_ filter: SCContentFilter, size: CGSize, scale: CGFloat) async throws -> CGImage {
        let configuration = SCStreamConfiguration()
        configuration.width = Int(size.width * scale)
        configuration.height = Int(size.height * scale)
        configuration.showsCursor = false
        configuration.ignoreShadowsSingleWindow = true
        return try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: configuration)
    }
}

extension NSScreen {
    var displayID: CGDirectDisplayID? {
        (deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value
    }
}
