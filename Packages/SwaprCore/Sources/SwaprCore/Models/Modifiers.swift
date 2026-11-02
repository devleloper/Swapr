/// The four modifier kinds, in the conventional macOS display order (⌃⌥⇧⌘).
public enum ModifierKind: String, Codable, CodingKeyRepresentable, CaseIterable, Comparable, Sendable {
    case control, option, shift, command

    public var symbol: String {
        switch self {
        case .control: "⌃"
        case .option: "⌥"
        case .shift: "⇧"
        case .command: "⌘"
        }
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        allCases.firstIndex(of: lhs)! < allCases.firstIndex(of: rhs)!
    }
}

public enum ModifierSide: String, Codable, Sendable {
    case left, right, either
}

/// A physical modifier key, e.g. the right Command key.
public struct PhysicalModifier: Hashable, Sendable {
    public let kind: ModifierKind
    /// Always `.left` or `.right`.
    public let side: ModifierSide

    public init(_ kind: ModifierKind, _ side: ModifierSide) {
        precondition(side != .either, "A physical key has a concrete side")
        self.kind = kind
        self.side = side
    }

    /// Device-dependent bits of `CGEventFlags` / `NSEvent.ModifierFlags` (IOKit `NX_DEVICE*KEYMASK`).
    private static let deviceMasks: [(mask: UInt64, key: PhysicalModifier)] = [
        (0x0000_0001, PhysicalModifier(.control, .left)),
        (0x0000_2000, PhysicalModifier(.control, .right)),
        (0x0000_0020, PhysicalModifier(.option, .left)),
        (0x0000_0040, PhysicalModifier(.option, .right)),
        (0x0000_0002, PhysicalModifier(.shift, .left)),
        (0x0000_0004, PhysicalModifier(.shift, .right)),
        (0x0000_0008, PhysicalModifier(.command, .left)),
        (0x0000_0010, PhysicalModifier(.command, .right)),
    ]

    /// Virtual key codes of the eight side-specific modifier keys.
    /// A `flagsChanged` event for any other key code (Caps Lock, Fn) is not a modifier tap.
    public static let keyCodes: Set<UInt16> = [54, 55, 56, 58, 59, 60, 61, 62]

    /// Decodes the set of currently held modifier keys from raw event flags.
    public static func pressed(inRawFlags flags: UInt64) -> Set<PhysicalModifier> {
        Set(deviceMasks.filter { flags & $0.mask != 0 }.map(\.key))
    }
}

/// Side-independent modifier flags used by key-combination hotkeys.
public struct ModifierFlags: OptionSet, Codable, Hashable, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    public static let control = ModifierFlags(rawValue: 1 << 0)
    public static let option = ModifierFlags(rawValue: 1 << 1)
    public static let shift = ModifierFlags(rawValue: 1 << 2)
    public static let command = ModifierFlags(rawValue: 1 << 3)

    private static let table: [(flag: ModifierFlags, kind: ModifierKind, carbon: UInt32, cocoa: UInt)] = [
        (.control, .control, 0x1000, 1 << 18),
        (.option, .option, 0x0800, 1 << 19),
        (.shift, .shift, 0x0200, 1 << 17),
        (.command, .command, 0x0100, 1 << 20),
    ]

    public var kinds: [ModifierKind] { Self.table.filter { contains($0.flag) }.map(\.kind) }

    /// Carbon `cmdKey` / `optionKey` / ... mask for `RegisterEventHotKey`.
    public var carbonFlags: UInt32 {
        Self.table.filter { contains($0.flag) }.reduce(0) { $0 | $1.carbon }
    }

    public init(carbonFlags: UInt32) {
        self = Self(Self.table.filter { carbonFlags & $0.carbon != 0 }.map(\.flag))
    }

    /// From `NSEvent.ModifierFlags.rawValue`.
    public init(cocoaFlags: UInt) {
        self = Self(Self.table.filter { cocoaFlags & $0.cocoa != 0 }.map(\.flag))
    }
}
