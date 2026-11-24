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
        stopPickingStage(cursor: .putBackLater)
        afterModifiersAreReleased {
            let windowsBefore = StageWindows.visibleSortedLeftToRight()
            StageStrip.addToCurrentStage(item, droppingAt: Self.currentStageCenter) {
                StageStripReveal.putCursorBack()
                Self.makeRoomForAddedWindows(previousWindowIDs: Set(windowsBefore.map(\.id)), strip: strip)
            }
        }
    }

    func confirmStage() {
        guard let strip = pickingStrip, strip.items.indices.contains(pickedIndex) else { return }
        let item = strip.items[pickedIndex]
        stopPickingStage(cursor: .putBackLater)
        afterModifiersAreReleased {
            StageStrip.open(item)
            StageStripReveal.putCursorBack()
        }
    }

    enum CursorAfterPicking {
        case putBack
        /// The action still needs the strip on screen; it puts the cursor back when done.
        case putBackLater
        /// The person grabbed the mouse, so the pointer stays where they moved it.
        case leaveWherePersonMovedIt
    }

    func stopPickingStage(cursor: CursorAfterPicking = .putBack) {
        guard pickingStrip != nil else { return }
        pickingStrip = nil
        revealGeneration += 1
        overlay.hide()
        switch cursor {
        case .putBack: StageStripReveal.putCursorBack()
        case .putBackLater: break
        case .leaveWherePersonMovedIt: StageStripReveal.forgetCursor()
        }
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
            StageStrip.removeFromCurrentStage(focused)
            Self.retileAfterWindowLeaves(focused.id, strip: strip)
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
            StageLayout.arrange(existing + added, besides: strip)
        }
    }

    private static func retileAfterWindowLeaves(_ leavingID: CGWindowID, strip: StageStrip, attemptsLeft: Int = addedWindowPollAttempts) {
        DispatchQueue.main.asyncAfter(deadline: .now() + addedWindowPollInterval) {
            let windows = StageWindows.visibleSortedLeftToRight()
            guard !windows.contains(where: { $0.id == leavingID }) else {
                if attemptsLeft > 0 { retileAfterWindowLeaves(leavingID, strip: strip, attemptsLeft: attemptsLeft - 1) }
                return
            }
            StageLayout.arrange(windows, besides: strip)
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
            pickedIndex = 0
            startPickingStage(near: focusedFrame)
        case .left, .right:
            let step = direction == .left ? -1 : 1
            let targetIndex = focusedIndex.map { $0 + step } ?? (direction == .left ? windows.count - 1 : 0)

            if windows.indices.contains(targetIndex) {
                focus(windows[targetIndex])
            } else {
                let strip = StageStrip.closest(to: focusedFrame)
                let pointsTowardStrip = strip.map { points(direction, towardStripOf: $0) } ?? (direction == .left)
                guard pointsTowardStrip else { return }
                pickedIndex = 0
                startPickingStage(strip, near: focusedFrame)
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
        revealGeneration += 1
        StageStripReveal.putCursorBack()
        let windows = StageWindows.visibleSortedLeftToRight()
        guard let edgeWindow = strip.isOnLeftEdge ? windows.first : windows.last else {
            overlay.hide()
            return
        }
        focus(edgeWindow, alwaysHighlight: true)
    }

    private func startPickingStage(near frame: CGRect?) {
        startPickingStage(StageStrip.closest(to: frame), near: frame)
    }

    /// The strip may be hidden behind edge-to-edge windows, so it is revealed first and read again once it slides in.
    private func startPickingStage(_ strip: StageStrip?, near frame: CGRect?) {
        StageStripReveal.reveal(near: frame, onLeftEdge: strip?.isOnLeftEdge ?? true)
        if let strip, !strip.items.isEmpty {
            pickingStrip = strip
            select(0, in: strip)
        }
        revealGeneration += 1
        refreshStripWhileItSlidesIn(near: frame, generation: revealGeneration)
    }

    private var revealGeneration = 0
    private static let stripRefreshInterval: TimeInterval = 0.05
    private static let stripRefreshAttempts = 10

    private func refreshStripWhileItSlidesIn(near frame: CGRect?, generation: Int, attemptsLeft: Int = stripRefreshAttempts) {
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.stripRefreshInterval) { [weak self] in
            guard let self, generation == self.revealGeneration else { return }
            if let strip = StageStrip.closest(to: frame), !strip.items.isEmpty {
                self.pickingStrip = strip
                self.select(min(self.pickedIndex, strip.items.count - 1), in: strip)
            }
            if attemptsLeft > 0 {
                self.refreshStripWhileItSlidesIn(near: frame, generation: generation, attemptsLeft: attemptsLeft - 1)
            } else if self.pickingStrip == nil {
                StageStripReveal.putCursorBack()
            }
        }
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
