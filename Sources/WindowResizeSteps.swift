import AppKit

/// Navigate + "+" / "-" resizes the focused window by a fixed step, so every press feels the same.
/// In Even and BSP stages it moves the lines the window shares with its neighbours, which give or take the same
/// space, so tiles never overlap. Elsewhere, or with no neighbour, it grows or shrinks around its center.
@MainActor
enum WindowResizeSteps {
    private static let stepsAcrossArea: CGFloat = 12
    private static let smallestTileShare = SharedLineResize.smallestTileShare

    static func grow() { resize(grows: true) }
    static func shrink() { resize(grows: false) }

    private static func resize(grows: Bool) {
        let windows = StageWindows.visibleSortedLeftToRight().map { window in
            StageWindow(element: window.element, pid: window.pid, id: window.id, frame: WindowAnimator.shared.frameIncludingAnimation(of: window))
        }
        guard let focusedID = StageWindows.focusedWindowID(),
              let focused = windows.first(where: { $0.id == focusedID }),
              let area = StageLayout.usableArea(around: focused.frame, besides: StageStrip.closest(to: focused.frame)) else { return }
        let step = CGSize(width: area.width / stepsAcrossArea, height: area.height / stepsAcrossArea)
        let sign: CGFloat = grows ? 1 : -1

        let mode = StageLayout.mode(for: windows)
        if mode == .even || mode == .bsp {
            var frames = Dictionary(uniqueKeysWithValues: windows.map { ($0.id, $0.frame) })
            let sideways = SharedLineResize.moveSharedLine(of: focused.id, axis: .horizontal, by: sign * step.width, in: &frames, area: area)
            let upDown = SharedLineResize.moveSharedLine(of: focused.id, axis: .vertical, by: sign * step.height, in: &frames, area: area)
            if sideways != .noNeighbour || upDown != .noNeighbour {
                let targets = windows.compactMap { window in frames[window.id].flatMap { $0 == window.frame ? nil : (window: window, frame: $0) } }
                if !targets.isEmpty { WindowAnimator.shared.animate(targets) }
                return
            }
        }
        resizeAroundCenter(focused, by: CGSize(width: sign * step.width, height: sign * step.height), within: area)
    }

    private static func resizeAroundCenter(_ window: StageWindow, by delta: CGSize, within area: CGRect) {
        let frame = window.frame
        let width = min(max(frame.width + delta.width, area.width * smallestTileShare), area.width)
        let height = min(max(frame.height + delta.height, area.height * smallestTileShare), area.height)
        var resized = CGRect(x: frame.midX - width / 2, y: frame.midY - height / 2, width: width, height: height)
        resized.origin.x = min(max(resized.minX, area.minX), area.maxX - width)
        resized.origin.y = min(max(resized.minY, area.minY), area.maxY - height)
        guard resized.integral != frame else { return }
        WindowAnimator.shared.animate([(window, resized.integral)], afterLanding: { AppSizes.rememberIfAlone(window.id) })
    }
}
