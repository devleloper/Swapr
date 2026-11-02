/// What a hotkey does.
public enum HotkeyAction: Hashable, Sendable {
    /// Switch to the input source with this identifier.
    case select(sourceID: String)
    /// Switch to the next input source in the cycle.
    case cycle
}

public struct HotkeyBinding: Hashable, Sendable {
    public let action: HotkeyAction
    public let hotkey: Hotkey

    public init(action: HotkeyAction, hotkey: Hotkey) {
        self.action = action
        self.hotkey = hotkey
    }
}

public enum MenuBarDisplay: String, Codable, CaseIterable, Sendable {
    /// Short code of the current layout, e.g. `EN`.
    case layoutCode
    /// A static keyboard icon.
    case icon
    /// No menu bar item; reopen the app to reach Settings.
    case hidden
}

/// Everything the user configures. Launch at login is deliberately absent:
/// macOS owns that state and is queried directly.
public struct Settings: Codable, Equatable, Sendable {
    /// Hotkeys keyed by input source identifier. Entries for sources that are
    /// currently disabled in macOS are kept so they work again once re-enabled.
    public var layoutHotkeys: [String: Hotkey] = [:]
    public var cycleHotkey: Hotkey?
    /// Sources skipped by the cycle hotkey. Exclusion (not inclusion) so newly
    /// added layouts take part in the cycle by default.
    public var cycleExcludedIDs: Set<String> = []
    public var menuBarDisplay: MenuBarDisplay = .layoutCode
    public var hasCompletedOnboarding = false

    public init() {}

    public var usesModifierTaps: Bool {
        allBindings.contains { if case .modifierTap = $0.hotkey { true } else { false } }
    }

    /// All configured bindings, including ones for currently unavailable sources.
    public var allBindings: [HotkeyBinding] {
        var result = layoutHotkeys
            .sorted { $0.key < $1.key }
            .map { HotkeyBinding(action: .select(sourceID: $0.key), hotkey: $0.value) }
        if let cycleHotkey {
            result.append(HotkeyBinding(action: .cycle, hotkey: cycleHotkey))
        }
        return result
    }

    /// Bindings that can fire with the given set of available sources.
    public func activeBindings(availableSourceIDs: Set<String>) -> [HotkeyBinding] {
        allBindings.filter {
            if case .select(let id) = $0.action { availableSourceIDs.contains(id) } else { true }
        }
    }

    /// The action whose modifier tap matches the physically tapped keys.
    public func action(forTap tapped: Set<PhysicalModifier>, availableSourceIDs: Set<String>) -> HotkeyAction? {
        activeBindings(availableSourceIDs: availableSourceIDs).first {
            if case .modifierTap(let tap) = $0.hotkey { tap.matches(tapped) } else { false }
        }?.action
    }

    public func hotkey(for action: HotkeyAction) -> Hotkey? {
        switch action {
        case .select(let id): layoutHotkeys[id]
        case .cycle: cycleHotkey
        }
    }

    public mutating func setHotkey(_ hotkey: Hotkey?, for action: HotkeyAction) {
        switch action {
        case .select(let id): layoutHotkeys[id] = hotkey
        case .cycle: cycleHotkey = hotkey
        }
    }
}

extension Settings {
    private enum CodingKeys: String, CodingKey {
        case layoutHotkeys, cycleHotkey, cycleExcludedIDs, menuBarDisplay, hasCompletedOnboarding
    }

    /// Tolerates missing or unknown values so settings survive app upgrades and downgrades.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init()
        layoutHotkeys = (try? container.decodeIfPresent([String: Hotkey].self, forKey: .layoutHotkeys)) ?? [:]
        cycleHotkey = try? container.decodeIfPresent(Hotkey.self, forKey: .cycleHotkey)
        cycleExcludedIDs = (try? container.decodeIfPresent(Set<String>.self, forKey: .cycleExcludedIDs)) ?? []
        menuBarDisplay = (try? container.decodeIfPresent(MenuBarDisplay.self, forKey: .menuBarDisplay)) ?? .layoutCode
        hasCompletedOnboarding = (try? container.decodeIfPresent(Bool.self, forKey: .hasCompletedOnboarding)) ?? false
    }
}
