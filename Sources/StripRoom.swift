import CoreGraphics

/// Stage Manager draws each stage's thumbnail at its own width and hides the strip when a window reaches it,
/// so the room left for the strip is the widest it has been on that screen, not only what it shows right now.
struct StripRoom {
    private var widestByScreen: [String: CGFloat] = [:]

    /// A reading wider than the fallback comes from a stray window or another screen's strip, so it is not kept.
    mutating func width(measured: CGFloat?, onScreen screenKey: String, fallback: CGFloat) -> CGFloat {
        let plausible = measured.flatMap { $0 <= fallback ? $0 : nil } ?? 0
        let widest = max(plausible, widestByScreen[screenKey] ?? 0)
        guard widest > 0 else { return fallback }
        widestByScreen[screenKey] = widest
        return widest
    }
}
