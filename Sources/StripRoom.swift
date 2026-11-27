import CoreGraphics

/// Stage Manager draws each stage's thumbnail at its own width and hides the strip when a window reaches it,
/// so the room left for the strip is the widest it has been on that screen, not only what it shows right now.
struct StripRoom {
    private var widestByScreen: [String: CGFloat] = [:]

    mutating func width(measured: CGFloat?, onScreen screenKey: String, fallback: CGFloat) -> CGFloat {
        let widest = max(measured ?? 0, widestByScreen[screenKey] ?? 0)
        guard widest > 0 else { return fallback }
        widestByScreen[screenKey] = widest
        return widest
    }
}
