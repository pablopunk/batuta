import AppKit
@preconcurrency import CoreGraphics

enum Direction {
    case left, right, up, down

    init?(keyCode: Int64, keys: DirectionKeys) {
        switch (keys, keyCode) {
        case (.arrows, 123), (.hjkl, 4): self = .left
        case (.arrows, 124), (.hjkl, 37): self = .right
        case (.arrows, 125), (.hjkl, 38): self = .down
        case (.arrows, 126), (.hjkl, 40): self = .up
        default: return nil
        }
    }
}

private enum KeyCode {
    static let returnKey: Int64 = 36
    static let keypadEnter: Int64 = 76
    static let escape: Int64 = 53
    static let digits: [Int64: Int] = [18: 1, 19: 2, 20: 3, 21: 4, 23: 5, 22: 6, 26: 7, 28: 8, 25: 9]
}

/// Global keyboard tap. It only swallows direction keys held with the chosen modifier, plus Return/Escape/direction keys while a stage is being picked.
@MainActor
final class HotkeyTap {
    var onDirection: ((Direction) -> Void)?
    var onMoveDirection: ((Direction) -> Void)?
    var onCycleTilingMode: (() -> Void)?
    var onStageNumber: ((Int) -> Void)?
    var onNavigateKeysHeld: ((Bool) -> Void)?
    var onConfirm: (() -> Void)?
    var onCancel: (() -> Void)?
    var onPointerTookOver: (() -> Void)?
    var onModifierReleased: (() -> Void)?
    var isPickingStage: () -> Bool = { false }

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var swallowedKeyCodes = Set<Int64>()
    private var holdsNavigateKeys = false

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
            let holdsNavigateKeysNow = holdsExactlyRequiredModifiers(event.flags)
            if holdsNavigateKeysNow != holdsNavigateKeys {
                holdsNavigateKeys = holdsNavigateKeysNow
                onNavigateKeysHeld?(holdsNavigateKeysNow)
            }
            return passThrough
        case .leftMouseDown, .rightMouseDown:
            if isPickingStage() { onPointerTookOver?() }
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
        guard !ShortcutRecording.isActive else { return false }
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let picking = isPickingStage()

        if !picking, ConfigStore.shared.config.effectiveCycleTilingModeShortcut.matches(keyCode: keyCode, flags: event.flags) {
            swallowedKeyCodes.insert(keyCode)
            onCycleTilingMode?()
            return true
        }

        if let number = KeyCode.digits[keyCode], holdsExactlyRequiredModifiers(event.flags) || (picking && holdsNoModifiers(event.flags)) {
            swallowedKeyCodes.insert(keyCode)
            onStageNumber?(number)
            return true
        }

        if let direction = Direction(keyCode: keyCode, keys: ConfigStore.shared.config.directionKeys) {
            if holdsExactlyRequiredModifiers(event.flags) || (picking && holdsNoModifiers(event.flags)) {
                swallowedKeyCodes.insert(keyCode)
                onDirection?(direction)
                return true
            }
            if holdsMoveModifiers(event.flags) {
                swallowedKeyCodes.insert(keyCode)
                onMoveDirection?(direction)
                return true
            }
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
        let required = ConfigStore.shared.config.requiredModifierFlags
        return !required.isEmpty && flags.intersection(ModifierKey.allEventFlags) == required
    }

    private func holdsMoveModifiers(_ flags: CGEventFlags) -> Bool {
        let config = ConfigStore.shared.config
        guard !config.requiredModifierFlags.isEmpty else { return false }
        return flags.intersection(ModifierKey.allEventFlags) == config.moveModifierFlags
    }

    private func holdsRequiredModifiers(_ flags: CGEventFlags) -> Bool {
        flags.contains(ConfigStore.shared.config.requiredModifierFlags)
    }

    private func holdsNoModifiers(_ flags: CGEventFlags) -> Bool {
        flags.intersection(ModifierKey.allEventFlags).isEmpty
    }
}
