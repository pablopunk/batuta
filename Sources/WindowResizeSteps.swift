import AppKit

/// Navigate + "+" grows the focused window by a third of the room it had when the first press measured it,
/// so three presses fill the usable area. Navigate + "-" walks back, then shrinks toward half its first size.
/// Letting go of Navigate ends the measurement.
@MainActor
final class WindowResizeSteps {
    private static let stepsToEdge = 3
    private static let smallestScale: CGFloat = 0.5

    private struct Measurement {
        let windowID: CGWindowID
        let startFrame: CGRect
        let grownFrame: CGRect
        let shrunkFrame: CGRect
        var step = 0
    }

    private var measurement: Measurement?

    func grow() { resize(by: 1) }
    func shrink() { resize(by: -1) }

    func forgetMeasurement() {
        measurement = nil
    }

    private func resize(by delta: Int) {
        let windows = StageWindows.visibleSortedLeftToRight()
        guard let focusedID = StageWindows.focusedWindowID(), let window = windows.first(where: { $0.id == focusedID }) else { return }
        if measurement?.windowID != window.id { measurement = measure(window) }
        guard var current = measurement else { return }
        current.step = min(max(current.step + delta, -Self.stepsToEdge), Self.stepsToEdge)
        measurement = current
        WindowAnimator.shared.animate([(window, frame(at: current))])
    }

    private func measure(_ window: StageWindow) -> Measurement? {
        guard let area = StageLayout.usableArea(around: window.frame, besides: StageStrip.closest(to: window.frame)) else { return nil }
        let start = window.frame
        let shrunkSize = CGSize(width: start.width * Self.smallestScale, height: start.height * Self.smallestScale)
        let shrunk = CGRect(x: start.midX - shrunkSize.width / 2, y: start.midY - shrunkSize.height / 2, width: shrunkSize.width, height: shrunkSize.height)
        return Measurement(windowID: window.id, startFrame: start, grownFrame: area.union(start).intersection(area), shrunkFrame: shrunk)
    }

    private func frame(at measurement: Measurement) -> CGRect {
        let progress = CGFloat(abs(measurement.step)) / CGFloat(Self.stepsToEdge)
        let end = measurement.step >= 0 ? measurement.grownFrame : measurement.shrunkFrame
        return Self.interpolate(measurement.startFrame, end, progress).integral
    }

    private static func interpolate(_ a: CGRect, _ b: CGRect, _ progress: CGFloat) -> CGRect {
        CGRect(
            x: a.minX + (b.minX - a.minX) * progress,
            y: a.minY + (b.minY - a.minY) * progress,
            width: a.width + (b.width - a.width) * progress,
            height: a.height + (b.height - a.height) * progress
        )
    }
}
