import AppKit

/// Traits are read when a window first shows, read once more after it settles, and then kept, so a window does not
/// flip between floating and tiled. Apps such as Chrome turn the full-screen button on a moment after a window opens.
@MainActor
enum WindowTraitsCache {
    private struct Entry {
        let firstSeen: CFTimeInterval
        var traits: WindowTraits
        var isFinal: Bool
    }

    private static let settleDelay: CFTimeInterval = 0.3
    private static let maxEntries = 256
    private static var entries: [CGWindowID: Entry] = [:]

    static func traits(of window: StageWindow, now: CFTimeInterval = CACurrentMediaTime()) -> WindowTraits {
        guard var entry = entries[window.id] else {
            entries[window.id] = Entry(firstSeen: now, traits: window.element.windowTraits, isFinal: false)
            return entries[window.id]!.traits
        }
        if !entry.isFinal && now - entry.firstSeen >= settleDelay {
            entry.traits = window.element.windowTraits
            entry.isFinal = true
            entries[window.id] = entry
        }
        return entry.traits
    }

    static func forgetWindows(otherThan shown: Set<CGWindowID>) {
        guard entries.count > maxEntries else { return }
        entries = entries.filter { shown.contains($0.key) }
    }
}
