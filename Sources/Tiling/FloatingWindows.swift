import ApplicationServices

/// Dialogs, About boxes, settings panes and other small fixed-size windows float above the tiles instead of taking one.
extension AXUIElement {
    var refusesTiling: Bool {
        !isSizeSettable || hasTitleBarWithoutWorkingZoomButton
    }

    private var isSizeSettable: Bool {
        var settable: DarwinBoolean = false
        return AXUIElementIsAttributeSettable(self, kAXSizeAttribute as CFString, &settable) == .success && settable.boolValue
    }

    private var hasTitleBarWithoutWorkingZoomButton: Bool {
        guard element(kAXCloseButtonAttribute) != nil else { return false }
        return element(kAXZoomButtonAttribute)?.bool(kAXEnabledAttribute) != true
    }
}

extension Array where Element == StageWindow {
    var tileable: [StageWindow] { filter(\.isTileable) }
}
