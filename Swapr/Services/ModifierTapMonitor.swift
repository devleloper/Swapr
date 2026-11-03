import Carbon
import Foundation
import SwaprCore

/// Detects modifier-only shortcuts (Right ⌘, ⇧⌘, …) system-wide with a listen-only event tap.
///
/// Privacy: the tap is passive and cannot alter or block input. For key presses it reads
/// only the event *type* to know that a non-modifier key was pressed; key codes and
/// characters are never read, kept or stored. Requires Input Monitoring permission.
@MainActor
final class ModifierTapMonitor {
    var onTap: ((Set<PhysicalModifier>) -> Void)?

    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var detector = ModifierTapDetector()

    var isRunning: Bool { tap != nil }

    /// Returns `false` when macOS refuses to create the tap (no Input Monitoring access).
    func start() -> Bool {
        guard tap == nil else { return true }

        let types: [CGEventType] = [.flagsChanged, .keyDown, .leftMouseDown, .rightMouseDown, .otherMouseDown, .scrollWheel]
        let mask = types.reduce(CGEventMask(0)) { $0 | (1 << $1.rawValue) }
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: mask,
            callback: eventTapCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else { return false }

        let source = CFMachPortCreateRunLoopSource(nil, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        self.tap = tap
        self.runLoopSource = source
        detector.reset()
        return true
    }

    func stop() {
        guard let tap else { return }
        CGEvent.tapEnable(tap: tap, enable: false)
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
        CFMachPortInvalidate(tap)
        self.tap = nil
        self.runLoopSource = nil
        detector.reset()
    }

    fileprivate func handle(type: CGEventType, keyCode: UInt16, flags: UInt64) {
        switch type {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            // macOS disables taps that stall or during secure input; resume and drop partial state.
            Log.hotkeys.notice("Event tap disabled by the system (\(type.rawValue)); re-enabling")
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
            detector.reset()
        case .flagsChanged where PhysicalModifier.keyCodes.contains(keyCode):
            let pressed = PhysicalModifier.pressed(inRawFlags: flags)
            guard let tapped = detector.modifiersChanged(to: pressed, at: ProcessInfo.processInfo.systemUptime) else { return }
            // With Secure Input on (password fields), macOS hides key presses from taps, so
            // ⌘V would look like a clean ⌘ tap. Ignore taps rather than switch by mistake.
            guard !IsSecureEventInputEnabled() else { return }
            onTap?(tapped)
        default:
            // A key press, click, scroll, Caps Lock or Fn: the gesture is not a clean tap.
            detector.otherInput()
        }
    }
}

private func eventTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    if let userInfo {
        // The key code is read for modifier changes only, to tell which modifier key changed.
        let keyCode = type == .flagsChanged ? UInt16(truncatingIfNeeded: event.getIntegerValueField(.keyboardEventKeycode)) : 0
        let flags = event.flags.rawValue
        // Points at the monitor, which is only touched on the main actor below.
        nonisolated(unsafe) let monitor = userInfo
        // The tap's run loop source is attached to the main run loop.
        MainActor.assumeIsolated {
            Unmanaged<ModifierTapMonitor>.fromOpaque(monitor).takeUnretainedValue()
                .handle(type: type, keyCode: keyCode, flags: flags)
        }
    }
    return Unmanaged.passUnretained(event)
}
