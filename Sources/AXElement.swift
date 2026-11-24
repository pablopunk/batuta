import AppKit
import ApplicationServices

@_silgen_name("_AXUIElementGetWindow")
private func _AXUIElementGetWindow(_ element: AXUIElement, _ windowID: UnsafeMutablePointer<CGWindowID>) -> AXError

extension AXUIElement {
    var children: [AXUIElement] { attribute(kAXChildrenAttribute) ?? [] }
    var windows: [AXUIElement] { attribute(kAXWindowsAttribute) ?? [] }
    var role: String? { attribute(kAXRoleAttribute) }
    var subrole: String? { attribute(kAXSubroleAttribute) }
    var title: String? { attribute(kAXTitleAttribute) }
    var identifier: String? { attribute(kAXIdentifierAttribute) }

    var frame: CGRect? {
        var origin = CGPoint.zero
        var size = CGSize.zero
        guard let position = axValue(kAXPositionAttribute), AXValueGetValue(position, .cgPoint, &origin),
              let dimensions = axValue(kAXSizeAttribute), AXValueGetValue(dimensions, .cgSize, &size) else {
            return nil
        }
        return CGRect(origin: origin, size: size)
    }

    var windowID: CGWindowID? {
        var id: CGWindowID = 0
        return _AXUIElementGetWindow(self, &id) == .success ? id : nil
    }

    func element(_ name: String) -> AXUIElement? {
        guard let raw: AnyObject = attribute(name), CFGetTypeID(raw) == AXUIElementGetTypeID() else { return nil }
        return (raw as! AXUIElement)
    }

    @discardableResult
    func perform(_ action: String) -> Bool {
        AXUIElementPerformAction(self, action as CFString) == .success
    }

    func set(_ name: String, to value: AnyObject) {
        AXUIElementSetAttributeValue(self, name as CFString, value)
    }

    func descendants(withIdentifier identifier: String, maxDepth: Int) -> [AXUIElement] {
        if self.identifier == identifier { return [self] }
        guard maxDepth > 0 else { return [] }
        return children.flatMap { $0.descendants(withIdentifier: identifier, maxDepth: maxDepth - 1) }
    }

    private func attribute<T>(_ name: String) -> T? {
        var value: AnyObject?
        guard AXUIElementCopyAttributeValue(self, name as CFString, &value) == .success else { return nil }
        return value as? T
    }

    private func axValue(_ name: String) -> AXValue? {
        guard let raw: AnyObject = attribute(name), CFGetTypeID(raw) == AXValueGetTypeID() else { return nil }
        return (raw as! AXValue)
    }
}

extension CGRect {
    /// Accessibility and CGWindow frames start at the top-left of the primary screen; AppKit starts at its bottom-left.
    var convertedToAppKit: CGRect {
        let primaryScreenHeight = NSScreen.screens.first?.frame.height ?? 0
        return CGRect(x: minX, y: primaryScreenHeight - maxY, width: width, height: height)
    }
}
