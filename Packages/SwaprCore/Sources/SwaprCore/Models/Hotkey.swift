/// A regular shortcut: a key pressed together with modifiers, e.g. ⌃⌥1.
public struct KeyCombo: Codable, Hashable, Sendable {
    /// macOS virtual key code (`kVK_*`).
    public var keyCode: UInt16
    public var modifiers: ModifierFlags

    public init(keyCode: UInt16, modifiers: ModifierFlags) {
        self.keyCode = keyCode
        self.modifiers = modifiers
    }
}

/// A shortcut made only of modifiers, triggered when they are pressed and released
/// without any other key in between, e.g. a tap of Right ⌘ or of ⇧⌘.
public struct ModifierTap: Codable, Hashable, Sendable {
    public var keys: [ModifierKind: ModifierSide]

    public init(keys: [ModifierKind: ModifierSide]) {
        precondition(!keys.isEmpty, "A modifier tap needs at least one key")
        self.keys = keys
    }

    /// Builds a tap from the keys a user physically pressed.
    /// A single key keeps its side (Right ⌘ ≠ Left ⌘); a chord matches either side (⇧⌘).
    /// Returns `nil` when the same modifier was held on both sides, which cannot be represented.
    public init?(recorded pressed: Set<PhysicalModifier>) {
        guard !pressed.isEmpty, Set(pressed.map(\.kind)).count == pressed.count else { return nil }
        if pressed.count == 1, let key = pressed.first {
            self.init(keys: [key.kind: key.side])
        } else {
            self.init(keys: Dictionary(uniqueKeysWithValues: pressed.map { ($0.kind, .either) }))
        }
    }

    public func matches(_ pressed: Set<PhysicalModifier>) -> Bool {
        guard pressed.count == keys.count else { return false }
        return pressed.allSatisfy { key in
            guard let side = keys[key.kind] else { return false }
            return side == .either || side == key.side
        }
    }
}

public enum Hotkey: Codable, Hashable, Sendable {
    case keyCombo(KeyCombo)
    case modifierTap(ModifierTap)
}
