import AppKit

/// Navigate + "+" moves each edge of the focused window a third of the way to the usable area's edge, measured
/// again on every press, so steps get smaller as the window nears the edges. Navigate + "-" undoes those steps
/// while Navigate is held, then shrinks the window around its center. Letting go of Navigate forgets the steps.
@MainActor
final class WindowResizeSteps {
    private static let shareOfRoomPerStep: CGFloat = 1 / 3
    private static let roomTooSmallToGrow: CGFloat = 8
    private static let shrinkShareOfSize: CGFloat = 1 / 6
    private static let smallestSize = CGSize(width: 320, height: 240)

    private var history: [(windowID: CGWindowID, frame: CGRect)] = []

    func grow() {
        guard let window = focusedWindow(),
              let area = StageLayout.usableArea(around: window.frame, besides: StageStrip.closest(to: window.frame)) else { return }
        let grown = Self.grown(window.frame, toward: area)
        guard grown != window.frame else { return }
        history.append((window.id, window.frame))
        WindowAnimator.shared.animate([(window, grown)])
    }

    func shrink() {
        guard let window = focusedWindow() else { return }
        if let last = history.last, last.windowID == window.id {
            history.removeLast()
            WindowAnimator.shared.animate([(window, last.frame)])
            return
        }
        history = []
        let shrunk = Self.shrunk(window.frame)
        guard shrunk != window.frame else { return }
        WindowAnimator.shared.animate([(window, shrunk)])
    }

    func forgetMeasurement() {
        history = []
    }

    private func focusedWindow() -> StageWindow? {
        guard let focusedID = StageWindows.focusedWindowID() else { return nil }
        if let last = history.last, last.windowID != focusedID { history = [] }
        return StageWindows.visibleSortedLeftToRight().first { $0.id == focusedID }
    }

    private static func grown(_ frame: CGRect, toward area: CGRect) -> CGRect {
        let left = step(frame.minX - area.minX)
        let right = step(area.maxX - frame.maxX)
        let top = step(frame.minY - area.minY)
        let bottom = step(area.maxY - frame.maxY)
        return CGRect(x: frame.minX - left, y: frame.minY - top, width: frame.width + left + right, height: frame.height + top + bottom).integral
    }

    /// A third of the room left; once less than the gap would remain, the rest is taken so growth ends.
    private static func step(_ room: CGFloat) -> CGFloat {
        guard room > roomTooSmallToGrow else { return 0 }
        let step = room * shareOfRoomPerStep
        return room - step <= roomTooSmallToGrow ? room : step
    }

    private static func shrunk(_ frame: CGRect) -> CGRect {
        let width = max(frame.width * (1 - shrinkShareOfSize), min(frame.width, smallestSize.width))
        let height = max(frame.height * (1 - shrinkShareOfSize), min(frame.height, smallestSize.height))
        return CGRect(x: frame.midX - width / 2, y: frame.midY - height / 2, width: width, height: height).integral
    }
}
