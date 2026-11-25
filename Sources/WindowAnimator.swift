import AppKit
import ApplicationServices
import QuartzCore

/// macOS has no API to animate another app's window, so frames are stepped through Accessibility on the display's refresh.
/// Only the position animates: resizing every frame makes apps relayout and stutter, so the size changes once.
@MainActor
final class WindowAnimator: NSObject {
    static let shared = WindowAnimator()

    private static let duration: CFTimeInterval = 0.3
    private static let enhancedUserInterfaceAttribute = "AXEnhancedUserInterface"

    private struct Move {
        let windowID: CGWindowID
        let pump: WindowPositionPump
        let startOrigin: CGPoint
        let target: CGRect
    }

    private var moves: [Move] = []
    private var startTime: CFTimeInterval = 0
    private var displayLink: CADisplayLink?
    private var pidsWithEnhancedUserInterface: Set<pid_t> = []
    private var afterLanding: (@MainActor () -> Void)?

    var isAnimating: Bool { displayLink != nil }

    /// Mid-animation a window has moved but not resized yet, so its live frame is neither old nor new.
    func frameIncludingAnimation(of window: StageWindow) -> CGRect {
        moves.first { $0.windowID == window.id }?.target ?? window.frame
    }

    func animate(_ targets: [(window: StageWindow, frame: CGRect)], afterLanding: (@MainActor () -> Void)? = nil) {
        self.afterLanding = nil
        finishImmediately()
        self.afterLanding = afterLanding
        disableEnhancedUserInterface(for: Set(targets.map(\.window.pid)))

        guard ConfigStore.shared.config.animateWindowMoves else {
            moves = targets.map { Move(windowID: $0.window.id, pump: WindowPositionPump(element: $0.window.element), startOrigin: $0.window.frame.origin, target: $0.frame) }
            finishImmediately()
            return
        }

        moves = targets.map { window, frame in
            let pump = WindowPositionPump(element: window.element)
            shrinkUpFront(window, toward: frame, using: pump)
            return Move(windowID: window.id, pump: pump, startOrigin: window.frame.origin, target: frame)
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
        let afterLanding = self.afterLanding
        self.afterLanding = nil
        landed.notify(queue: .main) { [weak self] in
            MainActor.assumeIsolated {
                self?.restoreEnhancedUserInterface()
                afterLanding?()
            }
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
