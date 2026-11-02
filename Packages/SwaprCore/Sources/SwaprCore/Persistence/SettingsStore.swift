import Foundation

/// Persists `Settings` as versioned JSON in `UserDefaults`.
public struct SettingsStore {
    static let currentVersion = 1

    private struct Envelope: Codable {
        var version: Int
        var settings: Settings
    }

    private let defaults: UserDefaults
    private let key: String

    public init(defaults: UserDefaults = .standard, key: String = "settings") {
        self.defaults = defaults
        self.key = key
    }

    /// Returns stored settings, or defaults when nothing is stored or the data is unreadable.
    public func load() -> Settings {
        guard let data = defaults.data(forKey: key),
              let envelope = try? JSONDecoder().decode(Envelope.self, from: data) else {
            return Settings()
        }
        return envelope.settings
    }

    public func save(_ settings: Settings) {
        let envelope = Envelope(version: Self.currentVersion, settings: settings)
        // Encoding plain value types cannot fail.
        guard let data = try? JSONEncoder().encode(envelope) else { return }
        defaults.set(data, forKey: key)
    }
}
