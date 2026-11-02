import Testing
@testable import SwaprCore

private let rightCommand = PhysicalModifier(.command, .right)
private let leftShift = PhysicalModifier(.shift, .left)

struct ModifierTapDetectorTests {
    @Test func cleanSingleTapIsDetected() {
        var detector = ModifierTapDetector()
        #expect(detector.modifiersChanged(to: [rightCommand], at: 0) == nil)
        #expect(detector.modifiersChanged(to: [], at: 0.1) == [rightCommand])
    }

    @Test func chordReportsAllKeysEvenWhenReleasedOneByOne() {
        var detector = ModifierTapDetector()
        _ = detector.modifiersChanged(to: [leftShift], at: 0)
        _ = detector.modifiersChanged(to: [leftShift, rightCommand], at: 0.05)
        #expect(detector.modifiersChanged(to: [rightCommand], at: 0.1) == nil)
        #expect(detector.modifiersChanged(to: [], at: 0.15) == [leftShift, rightCommand])
    }

    @Test func keyPressInBetweenCancelsTap() {
        var detector = ModifierTapDetector()
        _ = detector.modifiersChanged(to: [rightCommand], at: 0)
        detector.otherInput()
        #expect(detector.modifiersChanged(to: [], at: 0.1) == nil)
    }

    @Test func holdingTooLongCancelsTap() {
        var detector = ModifierTapDetector(maxDuration: 1)
        _ = detector.modifiersChanged(to: [rightCommand], at: 0)
        #expect(detector.modifiersChanged(to: [], at: 1.5) == nil)
    }

    @Test func otherInputWhileIdleDoesNotPoisonNextTap() {
        var detector = ModifierTapDetector()
        detector.otherInput()
        _ = detector.modifiersChanged(to: [rightCommand], at: 0)
        #expect(detector.modifiersChanged(to: [], at: 0.1) == [rightCommand])
    }

    @Test func interruptedGestureDoesNotAffectFollowingTap() {
        var detector = ModifierTapDetector()
        _ = detector.modifiersChanged(to: [rightCommand], at: 0)
        detector.otherInput()
        _ = detector.modifiersChanged(to: [], at: 0.1)
        _ = detector.modifiersChanged(to: [leftShift], at: 0.2)
        #expect(detector.modifiersChanged(to: [], at: 0.3) == [leftShift])
    }

    @Test func spuriousReleaseWithoutPressIsIgnored() {
        var detector = ModifierTapDetector()
        #expect(detector.modifiersChanged(to: [], at: 0) == nil)
    }

    @Test func decodesDeviceDependentFlags() {
        // Right ⌘ (0x10) + left ⇧ (0x02) + device-independent ⌘/⇧ bits + Caps Lock bit.
        let flags: UInt64 = 0x10 | 0x02 | (1 << 20) | (1 << 17) | (1 << 16)
        #expect(PhysicalModifier.pressed(inRawFlags: flags) == [rightCommand, leftShift])
        #expect(PhysicalModifier.pressed(inRawFlags: 0x2000 | 0x40) == [PhysicalModifier(.control, .right), PhysicalModifier(.option, .right)])
    }
}
