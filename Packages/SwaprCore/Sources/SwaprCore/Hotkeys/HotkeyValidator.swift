public enum HotkeyValidationError: Error, Equatable, Sendable {
    /// A plain key without modifiers would block normal typing.
    case requiresModifier
    /// ⌥ and ⇧ alone produce characters, and macOS 15+ restricts such global shortcuts.
    case optionOrShiftOnly
    /// Already assigned to another action in Swapr.
    case duplicate(of: HotkeyAction)
    /// Assigned to an enabled macOS shortcut (System Settings › Keyboard › Keyboard Shortcuts).
    case reservedBySystem
}

/// Decides whether a hotkey can be assigned. Rejecting up front is more reliable than
/// discovering a shortcut that silently never fires.
public struct HotkeyValidator: Sendable {
    public let systemShortcuts: Set<KeyCombo>

    public init(systemShortcuts: Set<KeyCombo>) {
        self.systemShortcuts = systemShortcuts
    }

    public func validate(_ hotkey: Hotkey, for action: HotkeyAction, in settings: Settings) -> HotkeyValidationError? {
        if case .keyCombo(let combo) = hotkey, let error = validate(combo) {
            return error
        }
        if let other = settings.allBindings.first(where: { $0.hotkey == hotkey && $0.action != action }) {
            return .duplicate(of: other.action)
        }
        return nil
    }

    private func validate(_ combo: KeyCombo) -> HotkeyValidationError? {
        if !KeyCodes.isFunctionKey(combo.keyCode) {
            if combo.modifiers.isEmpty { return .requiresModifier }
            if ModifierFlags([.option, .shift]).isSuperset(of: combo.modifiers) { return .optionOrShiftOnly }
        }
        return systemShortcuts.contains(combo) ? .reservedBySystem : nil
    }
}
