import Foundation

/// A keyboard input source (layout or input mode) that the user has enabled in macOS.
public struct InputSource: Identifiable, Hashable, Sendable {
    /// Stable system identifier, e.g. `com.apple.keylayout.Russian`.
    public let id: String
    /// Localized display name, e.g. `Russian`.
    public let name: String
    /// Short uppercase code for compact display, e.g. `RU`.
    public let shortCode: String

    public init(id: String, name: String, languages: [String]) {
        self.id = id
        self.name = name
        self.shortCode = Self.shortCode(name: name, languages: languages)
    }

    static func shortCode(name: String, languages: [String]) -> String {
        if let primary = languages.first,
           let code = Locale.Language(identifier: primary).languageCode?.identifier,
           !code.isEmpty {
            return String(code.prefix(3)).uppercased()
        }
        let letters = name.filter(\.isLetter)
        return letters.isEmpty ? "?" : String(letters.prefix(2)).uppercased()
    }
}
