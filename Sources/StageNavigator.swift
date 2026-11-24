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

    func confirmStage() {
        guard let strip = pickingStrip, strip.items.indices.contains(pickedIndex) else { return }
        let item = strip.items[pickedIndex]
        stopPickingStage()
        openOnceModifiersAreReleased(item)
    }

    func stopPickingStage() {
        guard pickingStrip != nil else { return }
        pickingStrip = nil
        overlay.hide()
    }

    /// Stage Manager reads held modifiers as "add to stage" style clicks, so the press waits until every modifier is up.
    private func openOnceModifiersAreReleased(_ item: StageStripItem, attemptsLeft: Int = 50) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) { [weak self] in
            if Self.isAnyModifierHeld, attemptsLeft > 0 {
                self?.openOnceModifiersAreReleased(item, attemptsLeft: attemptsLeft - 1)
            } else {
                StageStrip.open(item)
            }
        }
    }

    private static var isAnyModifierHeld: Bool {
        !CGEventSource.flagsState(.combinedSessionState).intersection(ModifierKey.allEventFlags).isEmpty
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
            if !points(direction, towardStripOf: strip) { stopPickingStage() }
        }
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

    private func focus(_ window: StageWindow) {
        StageWindows.focus(window)
        if ConfigStore.shared.config.highlightFocusedWindow { overlay.flash(around: window.frame) }
    }

    private func points(_ direction: Direction, towardStripOf strip: StageStrip) -> Bool {
        strip.isOnLeftEdge ? direction == .left : direction == .right
    }
}
