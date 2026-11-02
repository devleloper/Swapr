import Foundation

/// Recognizes modifier taps: one or more modifier keys pressed and then all released
/// without any other key, click or scroll in between, within `maxDuration`.
///
/// Pure state machine; the caller feeds it events and timestamps. It never sees which
/// regular key was pressed, only that *something* other than a modifier happened.
public struct ModifierTapDetector: Sendable {
    public var maxDuration: TimeInterval

    private var startTime: TimeInterval?
    private var peak: Set<PhysicalModifier> = []
    private var interrupted = false

    public init(maxDuration: TimeInterval = 1.0) {
        self.maxDuration = maxDuration
    }

    /// Call on every modifier change with the full set of currently held modifiers.
    /// Returns the tapped keys when the last modifier is released and the gesture was clean.
    public mutating func modifiersChanged(to pressed: Set<PhysicalModifier>, at time: TimeInterval) -> Set<PhysicalModifier>? {
        if !pressed.isEmpty {
            if startTime == nil {
                startTime = time
                peak = []
                interrupted = false
            }
            peak.formUnion(pressed)
            return nil
        }

        defer { reset() }
        guard let startTime, !interrupted, !peak.isEmpty, time - startTime <= maxDuration else { return nil }
        return peak
    }

    /// Call when a non-modifier input happens (key press, click, scroll).
    public mutating func otherInput() {
        if startTime != nil { interrupted = true }
    }

    public mutating func reset() {
        startTime = nil
        peak = []
        interrupted = false
    }
}
