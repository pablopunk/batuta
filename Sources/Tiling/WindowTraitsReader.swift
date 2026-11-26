import ApplicationServices

/// Reads `WindowTraits` from Accessibility, keeping "not there" apart from "could not read" (a busy app).
extension AXUIElement {
    var windowTraits: WindowTraits {
        WindowTraits(
            canResize: isSettable(kAXSizeAttribute),
            canMove: isSettable(kAXPositionAttribute),
            hasCloseButton: button(kAXCloseButtonAttribute).map { $0 != nil },
            fullScreenButton: fullScreenButtonState
        )
    }

    private var fullScreenButtonState: WindowTraits.FullScreenButton? {
        guard let lookup = button(kAXFullScreenButtonAttribute) else { return nil }
        guard let fullScreenButton = lookup else { return .disabledOrMissing }
        guard let isEnabled = fullScreenButton.readBool(kAXEnabledAttribute) else { return nil }
        return isEnabled ? .enabled : .disabledOrMissing
    }

    private func isSettable(_ name: String) -> Bool? {
        var settable: DarwinBoolean = false
        guard AXUIElementIsAttributeSettable(self, name as CFString, &settable) == .success else { return nil }
        return settable.boolValue
    }

    /// Nil when unreadable; `.some(nil)` when the window has no such button.
    private func button(_ name: String) -> AXUIElement?? {
        var value: AnyObject?
        switch AXUIElementCopyAttributeValue(self, name as CFString, &value) {
        case .success:
            guard let value, CFGetTypeID(value) == AXUIElementGetTypeID() else { return .some(nil) }
            return .some((value as! AXUIElement))
        case .noValue, .attributeUnsupported:
            return .some(nil)
        default:
            return nil
        }
    }

    private func readBool(_ name: String) -> Bool? {
        var value: AnyObject?
        guard AXUIElementCopyAttributeValue(self, name as CFString, &value) == .success else { return nil }
        return (value as? NSNumber)?.boolValue
    }
}
