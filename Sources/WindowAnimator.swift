import AppKit
import ApplicationServices
import QuartzCore
import os

/// macOS has no API to animate another app's window, so frames are stepped through Accessibility on the display's refresh.
/// Only the position animates: resizing every frame makes apps relayout and stutter, so the size changes once.
@MainActor
final class WindowAnimator: NSObject {
    static let shared = WindowAnimator()

    private static let duration: CFTimeInterval = 0.3
    private static let enhancedUserInterfaceAttribute = "AXEnhancedUserInterface"

    private struct Move {
        let pump: WindowPositionPump
        let startOrigin: CGPoint
        let target: CGRect
    }

    private var moves: [Move] = []
    private var startTime: CFTimeInterval = 0
    private var displayLink: CADisplayLink?
    private var pidsWithEnhancedUserInterface: Set<pid_t> = []

    private static let log = Logger(subsystem: "com.pablopunk.batuta", category: "animation")
    private let proxyOverlay = WindowProxyOverlay()
    private static let proxyDuration: CFTimeInterval = 0.32
    private static let proxyRevealDelay: TimeInterval = 0.06

    /// Prefers sliding pictures of the windows (smooth, needs Screen Recording) and falls back to stepping real windows.
    func animate(_ targets: [(window: StageWindow, frame: CGRect)]) {
        guard WindowSnapshotter.hasPermission else {
            Self.log.info("no screen recording permission, stepping windows through AX")
            WindowSnapshotter.requestPermission()
            animateThroughAccessibility(targets)
            return
        }

        Task { @MainActor in
            let captureStart = CACurrentMediaTime()
            guard let images = await WindowSnapshotter.snapshots(of: targets.map(\.window)) else {
                Self.log.info("window capture failed, stepping windows through AX")
                animateThroughAccessibility(targets)
                return
            }
            Self.log.info("sliding \(images.count) pictures, capture took \(Int((CACurrentMediaTime() - captureStart) * 1000))ms")
            slidePictures(images, targets)
        }
    }

    /// Real windows jump to their targets right away, hidden under their pictures, which then slide there too.
    private func slidePictures(_ images: [CGImage], _ targets: [(window: StageWindow, frame: CGRect)]) {
        finishImmediately()
        let screen = NSScreen.screens.first { $0.frame.intersects(targets[0].window.frame.convertedToAppKit) } ?? NSScreen.main
        guard let screen else { return animateThroughAccessibility(targets) }

        let proxies = zip(images, targets).map { image, target in (image: image, from: target.window.frame, to: target.frame) }
        let landed = DispatchGroup()

        proxyOverlay.slide(proxies, on: screen, duration: Self.proxyDuration) { [weak self] in
            landed.notify(queue: .main) {
                DispatchQueue.main.asyncAfter(deadline: .now() + Self.proxyRevealDelay) {
                    MainActor.assumeIsolated { self?.proxyOverlay.hide() }
                }
            }
        }

        disableEnhancedUserInterface(for: Set(targets.map(\.window.pid)))
        for target in targets {
            WindowPositionPump(element: target.window.element).land(on: target.frame, group: landed)
        }
        landed.notify(queue: .main) { [weak self] in
            MainActor.assumeIsolated { self?.restoreEnhancedUserInterface() }
        }
    }

    private func animateThroughAccessibility(_ targets: [(window: StageWindow, frame: CGRect)]) {
        finishImmediately()
        disableEnhancedUserInterface(for: Set(targets.map(\.window.pid)))

        moves = targets.map { window, frame in
            let pump = WindowPositionPump(element: window.element)
            shrinkUpFront(window, toward: frame, using: pump)
            return Move(pump: pump, startOrigin: window.frame.origin, target: frame)
        }
        startTime = CACurrentMediaTime()

        guard let link = NSScreen.main?.displayLink(target: self, selector: #selector(step)) else {
            finishImmediately()
            return
        }
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    @objc private func step(_ link: CADisplayLink) {
        let linear = min((CACurrentMediaTime() - startTime) / Self.duration, 1)
        guard linear < 1 else {
            finishImmediately()
            return
        }
        let progress = Self.easeOut(linear)
        for move in moves {
            move.pump.move(to: Self.interpolate(move.startOrigin, move.target.origin, progress))
        }
    }

    private func finishImmediately() {
        displayLink?.invalidate()
        displayLink = nil
        guard !moves.isEmpty else { return }
        let landed = DispatchGroup()
        for move in moves { move.pump.land(on: move.target, group: landed) }
        moves = []
        landed.notify(queue: .main) { [weak self] in
            MainActor.assumeIsolated { self?.restoreEnhancedUserInterface() }
        }
    }

    /// Shrinking first keeps a window from covering its neighbour while it slides; growing waits until the end.
    private func shrinkUpFront(_ window: StageWindow, toward target: CGRect, using pump: WindowPositionPump) {
        let size = CGSize(width: min(window.frame.width, target.width), height: min(window.frame.height, target.height))
        guard size != window.frame.size else { return }
        pump.resize(to: size)
    }

    /// Chromium and Electron apps animate their own AX resizes while this is on, which makes stepped moves very slow.
    private func disableEnhancedUserInterface(for pids: Set<pid_t>) {
        for pid in pids {
            let app = AXUIElementCreateApplication(pid)
            guard app.bool(Self.enhancedUserInterfaceAttribute) == true else { continue }
            app.set(Self.enhancedUserInterfaceAttribute, to: kCFBooleanFalse)
            pidsWithEnhancedUserInterface.insert(pid)
        }
    }

    private func restoreEnhancedUserInterface() {
        for pid in pidsWithEnhancedUserInterface {
            AXUIElementCreateApplication(pid).set(Self.enhancedUserInterfaceAttribute, to: kCFBooleanTrue)
        }
        pidsWithEnhancedUserInterface = []
    }

    private static func easeOut(_ t: Double) -> CGFloat {
        CGFloat(1 - pow(1 - t, 3))
    }

    private static func interpolate(_ a: CGPoint, _ b: CGPoint, _ p: CGFloat) -> CGPoint {
        CGPoint(x: a.x + (b.x - a.x) * p, y: a.y + (b.y - a.y) * p)
    }
}
