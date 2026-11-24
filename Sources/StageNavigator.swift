import AppKit

/// Moves focus between the windows of the current stage, and past the edge into the Stage Manager strip.
@MainActor
final class StageNavigator {
    private let overlay = HighlightOverlay()
    private var pickingStrip: StageStrip?
    private var pickedIndex = 0

    var isPickingStage: Bool { pickingStrip != nil }

    func move(_ direction: Direction) {
        if let strip = pickingStrip {
            moveInsideStrip(strip, direction)
        } else {
            moveAmongWindows(direction)
        }
    }

    func moveItem(_ direction: Direction) {
        if let strip = pickingStrip {
            addPickedStageToCurrentStage(strip, direction)
        } else {
            moveFocusedWindow(direction)
        }
    }

    private func addPickedStageToCurrentStage(_ strip: StageStrip, _ direction: Direction) {
        guard strip.items.indices.contains(pickedIndex), !points(direction, towardStripOf: strip) else { return }
        let item = strip.items[pickedIndex]
        stopPickingStage()
        afterModifiersAreReleased {
            let windowsBefore = StageWindows.visibleSortedLeftToRight()
            StageStrip.addToCurrentStage(item, droppingAt: Self.currentStageCenter) {
                Self.makeRoomForAddedWindows(previousWindowIDs: Set(windowsBefore.map(\.id)), strip: strip)
            }
        }
    }

    func confirmStage() {
        guard let strip = pickingStrip, strip.items.indices.contains(pickedIndex) else { return }
        let item = strip.items[pickedIndex]
        stopPickingStage()
        afterModifiersAreReleased { StageStrip.open(item) }
    }

    func stopPickingStage() {
        guard pickingStrip != nil else { return }
        pickingStrip = nil
        overlay.hide()
    }

    /// Stage Manager reads held modifiers as "add to stage" style clicks, so the press waits until every modifier is up.
    private func afterModifiersAreReleased(attemptsLeft: Int = 50, _ action: @escaping @MainActor () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) { [weak self] in
            if Self.isAnyModifierHeld, attemptsLeft > 0 {
                self?.afterModifiersAreReleased(attemptsLeft: attemptsLeft - 1, action)
            } else {
                action()
            }
        }
    }

    private static var isAnyModifierHeld: Bool {
        !CGEventSource.flagsState(.combinedSessionState).intersection(ModifierKey.allEventFlags).isEmpty
    }

    /// Swaps the focused window with its neighbour; past the edge next to the strip, it leaves the stage.
    private func moveFocusedWindow(_ direction: Direction) {
        guard direction == .left || direction == .right else { return }
        let windows = StageWindows.visibleSortedLeftToRight()
        guard let focusedID = StageWindows.focusedWindowID(),
              let focusedIndex = windows.firstIndex(where: { $0.id == focusedID }) else { return }
        let focused = windows[focusedIndex]
        let neighbourIndex = focusedIndex + (direction == .left ? -1 : 1)

        if windows.indices.contains(neighbourIndex) {
            let neighbour = windows[neighbourIndex]
            WindowAnimator.shared.animate([(focused, neighbour.frame), (neighbour, focused.frame)])
            if ConfigStore.shared.config.highlightFocusedWindow { overlay.flash(around: neighbour.frame) }
        } else if let strip = StageStrip.closest(to: focused.frame), points(direction, towardStripOf: strip) {
            afterModifiersAreReleased { StageStrip.removeFromCurrentStage(focused, strip: strip) }
        }
    }

    private static let addedWindowPollInterval: TimeInterval = 0.03
    private static let addedWindowPollAttempts = 50

    /// Polls until Stage Manager shows the dropped window full size, then lays out right away.
    /// Existing windows keep their left-to-right order and the newcomers take the columns on the right.
    private static func makeRoomForAddedWindows(previousWindowIDs: Set<CGWindowID>, strip: StageStrip, attemptsLeft: Int = addedWindowPollAttempts) {
        DispatchQueue.main.asyncAfter(deadline: .now() + addedWindowPollInterval) {
            let windows = StageWindows.visibleSortedLeftToRight()
            let added = windows.filter { !previousWindowIDs.contains($0.id) }
            guard !added.isEmpty else {
                if attemptsLeft > 0 { makeRoomForAddedWindows(previousWindowIDs: previousWindowIDs, strip: strip, attemptsLeft: attemptsLeft - 1) }
                return
            }
            let existing = windows.filter { previousWindowIDs.contains($0.id) }
            StageLayout.arrangeInColumns(existing + added, besides: strip)
        }
    }

    private static var currentStageCenter: CGPoint {
        let focusedID = StageWindows.focusedWindowID()
        let windows = StageWindows.visibleSortedLeftToRight()
        if let frame = (windows.first { $0.id == focusedID } ?? windows.first)?.frame { return frame.center }
        let screen = NSScreen.main?.frame ?? .zero
        return CGPoint(x: screen.midX, y: screen.midY)
    }

    private func moveAmongWindows(_ direction: Direction) {
        let windows = StageWindows.visibleSortedLeftToRight()
        let focusedIndex = StageWindows.focusedWindowID().flatMap { id in windows.firstIndex { $0.id == id } }
        let focusedFrame = focusedIndex.map { windows[$0].frame }

        switch direction {
        case .up, .down:
            startPickingStage(near: focusedFrame)
        case .left, .right:
            let step = direction == .left ? -1 : 1
            let targetIndex = focusedIndex.map { $0 + step } ?? (direction == .left ? windows.count - 1 : 0)

            if windows.indices.contains(targetIndex) {
                focus(windows[targetIndex])
            } else if let strip = StageStrip.closest(to: focusedFrame), points(direction, towardStripOf: strip) {
                startPickingStage(strip)
            }
        }
    }

    private func moveInsideStrip(_ strip: StageStrip, _ direction: Direction) {
        switch direction {
        case .up:
            select(max(pickedIndex - 1, 0), in: strip)
        case .down:
            select(min(pickedIndex + 1, strip.items.count - 1), in: strip)
        case .left, .right:
            if !points(direction, towardStripOf: strip) { returnToWindowNearest(strip) }
        }
    }

    private func returnToWindowNearest(_ strip: StageStrip) {
        pickingStrip = nil
        let windows = StageWindows.visibleSortedLeftToRight()
        guard let edgeWindow = strip.isOnLeftEdge ? windows.first : windows.last else {
            overlay.hide()
            return
        }
        focus(edgeWindow, alwaysHighlight: true)
    }

    private func startPickingStage(near frame: CGRect?) {
        guard let strip = StageStrip.closest(to: frame) else { return }
        startPickingStage(strip)
    }

    private func startPickingStage(_ strip: StageStrip) {
        guard !strip.items.isEmpty else { return }
        pickingStrip = strip
        select(0, in: strip)
    }

    private func select(_ index: Int, in strip: StageStrip) {
        pickedIndex = index
        overlay.show(around: strip.items[index].frame)
    }

    private func focus(_ window: StageWindow, alwaysHighlight: Bool = false) {
        StageWindows.focus(window)
        if alwaysHighlight || ConfigStore.shared.config.highlightFocusedWindow {
            overlay.flash(around: window.frame)
        } else {
            overlay.hide()
        }
    }

    private func points(_ direction: Direction, towardStripOf strip: StageStrip) -> Bool {
        strip.isOnLeftEdge ? direction == .left : direction == .right
    }
}
