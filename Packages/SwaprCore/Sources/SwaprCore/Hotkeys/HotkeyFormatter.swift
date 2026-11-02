/// Human-readable hotkey labels in the standard macOS style, e.g. `⌃⌥1`, `Right ⌘`, `⇧⌘`.
public enum HotkeyFormatter {
    /// - Parameter characterName: resolves a character key code against the current layout.
    public static func string(for hotkey: Hotkey, characterName: (UInt16) -> String?) -> String {
        switch hotkey {
        case .keyCombo(let combo):
            let modifiers = combo.modifiers.kinds.map(\.symbol).joined()
            let key = KeyCodes.fixedName(for: combo.keyCode)
                ?? characterName(combo.keyCode)?.uppercased()
                ?? "Key \(combo.keyCode)"
            return modifiers + key
        case .modifierTap(let tap):
            if tap.keys.count == 1, let (kind, side) = tap.keys.first, side != .either {
                return "\(side == .left ? "Left" : "Right") \(kind.symbol)"
            }
            return tap.keys.keys.sorted().map(\.symbol).joined()
        }
    }
}
