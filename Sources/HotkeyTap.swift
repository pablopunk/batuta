import AppKit
@preconcurrency import CoreGraphics

enum Direction {
    case left, right, up, down

    init?(keyCode: Int64) {
        switch keyCode {
        case 123: self = .left
        case 124: self = .right
        case 125: self = .down
        case 126: self = .up
        default: return nil
        }
    }
}

private enum KeyCode {
    static let returnKey: Int64 = 36
    static let keypadEnter: Int64 = 76
    static let escape: Int64 = 53
}

/// Global keyboard tap. It only swallows arrows held with the chosen modifier, plus Return/Escape/arrows while a stage is being picked.
@MainActor
final class HotkeyTap {
    var onDirection: ((Direction) -> Void)?
    var onConfirm: (() -> Void)?
    var onCancel: (() -> Void)?
    var onModifierReleased: (() -> Void)?
    var isPickingStage: () -> Bool = { false }

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var swallowedKeyCodes = Set<Int64>()

    var isRunning: Bool { eventTap != nil }

    func start() {
        guard eventTap == nil else { return }

        let eventTypes: [CGEventType] = [.keyDown, .keyUp, .flagsChanged, .leftMouseDown, .rightMouseDown, .tapDisabledByTimeout, .tapDisabledByUserInput]
        let mask = eventTypes.reduce(CGEventMask(0)) { $0 | (1 << $1.rawValue) }

        let callback: CGEventTapCallBack = { _, type, event, userInfo in
            guard let userInfo else { return Unmanaged.passUnretained(event) }
            let tap = Unmanaged<HotkeyTap>.fromOpaque(userInfo).takeUnretainedValue()
            return MainActor.assumeIsolated { tap.handle(type: type, event: event) }
        }

        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("[Batuta] failed to create event tap")
            return
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        self.eventTap = eventTap
        self.runLoopSource = source
    }

    func stop() {
        if let runLoopSource { CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes) }
        if let eventTap { CFMachPortInvalidate(eventTap) }
        runLoopSource = nil
        eventTap = nil
    }

    private func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        let passThrough = Unmanaged.passUnretained(event)

        switch type {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            if let eventTap { CGEvent.tapEnable(tap: eventTap, enable: true) }
            return passThrough
        case .flagsChanged:
            if !holdsRequiredModifiers(event.flags) { onModifierReleased?() }
            return passThrough
        case .leftMouseDown, .rightMouseDown:
            if isPickingStage() { onCancel?() }
            return passThrough
        case .keyDown:
            return handleKeyDown(event) ? nil : passThrough
        case .keyUp:
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            return swallowedKeyCodes.remove(keyCode) != nil ? nil : passThrough
        default:
            return passThrough
        }
    }

    private func handleKeyDown(_ event: CGEvent) -> Bool {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let picking = isPickingStage()

        if let direction = Direction(keyCode: keyCode),
           holdsExactlyRequiredModifiers(event.flags) || (picking && holdsNoModifiers(event.flags)) {
            swallowedKeyCodes.insert(keyCode)
            onDirection?(direction)
            return true
        }

        guard picking else { return false }

        switch keyCode {
        case KeyCode.returnKey, KeyCode.keypadEnter:
            swallowedKeyCodes.insert(keyCode)
            onConfirm?()
            return true
        case KeyCode.escape:
            swallowedKeyCodes.insert(keyCode)
            onCancel?()
            return true
        default:
            return false
        }
    }

    private func holdsExactlyRequiredModifiers(_ flags: CGEventFlags) -> Bool {
        let required = Settings.requiredModifierFlags
        return !required.isEmpty && flags.intersection(ModifierKey.allEventFlags) == required
    }

    private func holdsRequiredModifiers(_ flags: CGEventFlags) -> Bool {
        flags.contains(Settings.requiredModifierFlags)
    }

    private func holdsNoModifiers(_ flags: CGEventFlags) -> Bool {
        flags.intersection(ModifierKey.allEventFlags).isEmpty
    }
}
