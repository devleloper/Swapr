import Testing
@testable import SwaprCore

struct ModifierTapTests {
    @Test func singleKeyKeepsItsSide() throws {
        let tap = try #require(ModifierTap(recorded: [PhysicalModifier(.command, .right)]))
        #expect(tap.keys == [.command: .right])
        #expect(tap.matches([PhysicalModifier(.command, .right)]))
        #expect(!tap.matches([PhysicalModifier(.command, .left)]))
    }

    @Test func chordMatchesEitherSide() throws {
        let tap = try #require(ModifierTap(recorded: [PhysicalModifier(.shift, .left), PhysicalModifier(.command, .left)]))
        #expect(tap.keys == [.shift: .either, .command: .either])
        #expect(tap.matches([PhysicalModifier(.shift, .right), PhysicalModifier(.command, .left)]))
        #expect(!tap.matches([PhysicalModifier(.command, .left)]))
        #expect(!tap.matches([PhysicalModifier(.shift, .left), PhysicalModifier(.command, .left), PhysicalModifier(.option, .left)]))
    }

    @Test func bothSidesOfSameModifierCannotBeRecorded() {
        #expect(ModifierTap(recorded: [PhysicalModifier(.shift, .left), PhysicalModifier(.shift, .right)]) == nil)
        #expect(ModifierTap(recorded: []) == nil)
    }
}

struct ModifierFlagsTests {
    @Test func convertsToAndFromCarbon() {
        let flags: ModifierFlags = [.command, .shift]
        #expect(flags.carbonFlags == 0x0300)
        #expect(ModifierFlags(carbonFlags: 0x0300) == flags)
        // The Fn bit (1 << 17) used by system shortcuts is ignored.
        #expect(ModifierFlags(carbonFlags: 0x1000 | (1 << 17)) == .control)
    }

    @Test func convertsFromCocoa() {
        #expect(ModifierFlags(cocoaFlags: (1 << 18) | (1 << 19)) == [.control, .option])
    }
}

struct HotkeyFormatterTests {
    private func format(_ hotkey: Hotkey) -> String {
        HotkeyFormatter.string(for: hotkey) { $0 == 18 ? "1" : ($0 == 40 ? "k" : nil) }
    }

    @Test func formatsCombosInStandardOrder() {
        #expect(format(.keyCombo(KeyCombo(keyCode: 40, modifiers: [.command, .shift, .control, .option]))) == "⌃⌥⇧⌘K")
        #expect(format(.keyCombo(KeyCombo(keyCode: 49, modifiers: [.control]))) == "⌃Space")
        #expect(format(.keyCombo(KeyCombo(keyCode: 122, modifiers: []))) == "F1")
        #expect(format(.keyCombo(KeyCombo(keyCode: 999, modifiers: [.command]))) == "⌘Key 999")
    }

    @Test func formatsModifierTaps() {
        #expect(format(.modifierTap(ModifierTap(keys: [.command: .right]))) == "Right ⌘")
        #expect(format(.modifierTap(ModifierTap(keys: [.option: .left]))) == "Left ⌥")
        #expect(format(.modifierTap(ModifierTap(keys: [.command: .either, .shift: .either]))) == "⇧⌘")
    }
}

struct HotkeyValidatorTests {
    private let controlSpace = KeyCombo(keyCode: 49, modifiers: [.control])
    private var validator: HotkeyValidator { HotkeyValidator(systemShortcuts: [controlSpace]) }

    @Test func rejectsPlainKeysButAllowsFunctionKeys() {
        let settings = Settings()
        #expect(validator.validate(.keyCombo(KeyCombo(keyCode: 0, modifiers: [])), for: .cycle, in: settings) == .requiresModifier)
        #expect(validator.validate(.keyCombo(KeyCombo(keyCode: 122, modifiers: [])), for: .cycle, in: settings) == nil)
    }

    @Test func rejectsOptionAndShiftOnlyCombos() {
        let settings = Settings()
        for modifiers: ModifierFlags in [.shift, .option, [.option, .shift]] {
            #expect(validator.validate(.keyCombo(KeyCombo(keyCode: 0, modifiers: modifiers)), for: .cycle, in: settings) == .optionOrShiftOnly)
        }
        #expect(validator.validate(.keyCombo(KeyCombo(keyCode: 0, modifiers: [.option, .command])), for: .cycle, in: settings) == nil)
    }

    @Test func rejectsSystemShortcuts() {
        #expect(validator.validate(.keyCombo(controlSpace), for: .cycle, in: Settings()) == .reservedBySystem)
    }

    @Test func rejectsDuplicatesButAllowsReassigningSameAction() {
        let tap = Hotkey.modifierTap(ModifierTap(keys: [.command: .right]))
        var settings = Settings()
        settings.setHotkey(tap, for: .select(sourceID: "en"))
        #expect(validator.validate(tap, for: .cycle, in: settings) == .duplicate(of: .select(sourceID: "en")))
        #expect(validator.validate(tap, for: .select(sourceID: "en"), in: settings) == nil)
        #expect(validator.validate(.modifierTap(ModifierTap(keys: [.command: .left])), for: .cycle, in: settings) == nil)
    }
}

struct HotkeyRecorderTests {
    @Test func recordsKeyCombo() {
        var recorder = HotkeyRecorder()
        _ = recorder.modifiersChanged(to: [PhysicalModifier(.command, .left)], at: 0)
        #expect(recorder.keyDown(keyCode: 18, modifiers: .command) == .recorded(.keyCombo(KeyCombo(keyCode: 18, modifiers: .command))))
        // Releasing ⌘ after the combo must not also record a tap.
        #expect(recorder.modifiersChanged(to: [], at: 0.2) == nil)
    }

    @Test func recordsModifierTap() {
        var recorder = HotkeyRecorder()
        _ = recorder.modifiersChanged(to: [PhysicalModifier(.option, .right)], at: 0)
        #expect(recorder.modifiersChanged(to: [], at: 0.3) == .recorded(.modifierTap(ModifierTap(keys: [.option: .right]))))
    }

    @Test func escapeCancelsAndDeleteClears() {
        var recorder = HotkeyRecorder()
        #expect(recorder.keyDown(keyCode: KeyCodes.escape, modifiers: []) == .cancelled)
        #expect(recorder.keyDown(keyCode: KeyCodes.delete, modifiers: []) == .cleared)
        #expect(recorder.keyDown(keyCode: KeyCodes.forwardDelete, modifiers: []) == .cleared)
        #expect(recorder.keyDown(keyCode: KeyCodes.escape, modifiers: .command) == .recorded(.keyCombo(KeyCombo(keyCode: KeyCodes.escape, modifiers: .command))))
    }
}
