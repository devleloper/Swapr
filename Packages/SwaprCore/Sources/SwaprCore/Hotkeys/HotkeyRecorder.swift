import Foundation

/// Turns raw key events captured while the user records a shortcut into a hotkey.
public struct HotkeyRecorder: Sendable {
    public enum Outcome: Equatable, Sendable {
        case recorded(Hotkey)
        /// Esc without modifiers.
        case cancelled
        /// ⌫ or ⌦ without modifiers.
        case cleared
    }

    // Longer than the default: modifiers are pressed more slowly while recording.
    private var detector = ModifierTapDetector(maxDuration: 3)

    public init() {}

    public mutating func modifiersChanged(to pressed: Set<PhysicalModifier>, at time: TimeInterval) -> Outcome? {
        guard let tapped = detector.modifiersChanged(to: pressed, at: time),
              let tap = ModifierTap(recorded: tapped) else { return nil }
        return .recorded(.modifierTap(tap))
    }

    public mutating func keyDown(keyCode: UInt16, modifiers: ModifierFlags) -> Outcome {
        detector.otherInput()
        if modifiers.isEmpty {
            if keyCode == KeyCodes.escape { return .cancelled }
            if keyCode == KeyCodes.delete || keyCode == KeyCodes.forwardDelete { return .cleared }
        }
        return .recorded(.keyCombo(KeyCombo(keyCode: keyCode, modifiers: modifiers)))
    }
}
