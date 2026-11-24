import AppKit
import ApplicationServices

/// macOS has no API to animate another app's window, so frames are stepped through Accessibility at ~60fps.
@MainActor
enum WindowAnimator {
    private static let duration: TimeInterval = 0.22
    private static let frameCount = 14

    static func animate(_ window: StageWindow, to target: CGRect) {
        let start = window.frame
        for frame in 1...frameCount {
            let progress = easeOut(Double(frame) / Double(frameCount))
            let isLastFrame = frame == frameCount
            DispatchQueue.main.asyncAfter(deadline: .now() + duration * Double(frame) / Double(frameCount)) {
                let rect = isLastFrame ? target : interpolate(from: start, to: target, progress: progress)
                window.element.setFrame(rect, settleSize: isLastFrame)
            }
        }
    }

    private static func easeOut(_ t: Double) -> CGFloat {
        CGFloat(1 - pow(1 - t, 3))
    }

    private static func interpolate(from a: CGRect, to b: CGRect, progress p: CGFloat) -> CGRect {
        CGRect(
            x: a.minX + (b.minX - a.minX) * p,
            y: a.minY + (b.minY - a.minY) * p,
            width: a.width + (b.width - a.width) * p,
            height: a.height + (b.height - a.height) * p
        )
    }
}
