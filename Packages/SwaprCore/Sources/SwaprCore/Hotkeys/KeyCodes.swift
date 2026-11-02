/// Names of keys whose label does not depend on the keyboard layout.
/// Values are macOS virtual key codes (`kVK_*` from Carbon's `Events.h`).
public enum KeyCodes {
    public static let escape: UInt16 = 53
    public static let delete: UInt16 = 51
    public static let forwardDelete: UInt16 = 117

    public static let functionKeys: [UInt16: String] = [
        122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6", 98: "F7", 100: "F8",
        101: "F9", 109: "F10", 103: "F11", 111: "F12", 105: "F13", 107: "F14", 113: "F15",
        106: "F16", 64: "F17", 79: "F18", 80: "F19", 90: "F20",
    ]

    private static let specialKeys: [UInt16: String] = [
        36: "↩", 48: "⇥", 49: "Space", 51: "⌫", 53: "⎋", 117: "⌦", 76: "⌤", 114: "Help",
        115: "↖", 119: "↘", 116: "⇞", 121: "⇟", 123: "←", 124: "→", 125: "↓", 126: "↑",
    ]

    public static func isFunctionKey(_ keyCode: UInt16) -> Bool {
        functionKeys[keyCode] != nil
    }

    /// Layout-independent name, or `nil` for character keys that must be resolved
    /// against the current keyboard layout.
    public static func fixedName(for keyCode: UInt16) -> String? {
        functionKeys[keyCode] ?? specialKeys[keyCode]
    }
}
