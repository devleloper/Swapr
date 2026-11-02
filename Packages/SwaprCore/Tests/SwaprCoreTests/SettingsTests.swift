import Foundation
import Testing
@testable import SwaprCore

private let english = InputSource(id: "com.apple.keylayout.US", name: "U.S.", languages: ["en"])
private let russian = InputSource(id: "com.apple.keylayout.Russian", name: "Russian", languages: ["ru", "bg"])
private let german = InputSource(id: "com.apple.keylayout.German", name: "German", languages: ["de"])

struct InputSourceTests {
    @Test func shortCodeComesFromPrimaryLanguage() {
        #expect(english.shortCode == "EN")
        #expect(russian.shortCode == "RU")
        #expect(InputSource(id: "x", name: "Hindi Latin", languages: ["hi_Latn"]).shortCode == "HI")
    }

    @Test func shortCodeFallsBackToName() {
        #expect(InputSource(id: "x", name: "Unicode Hex Input", languages: []).shortCode == "UN")
    }
}

struct LayoutCyclerTests {
    private let sources = [english, russian, german]

    @Test func advancesAndWraps() {
        #expect(LayoutCycler.next(after: english.id, in: sources, excluding: [])?.id == russian.id)
        #expect(LayoutCycler.next(after: german.id, in: sources, excluding: [])?.id == english.id)
    }

    @Test func skipsExcludedSources() {
        #expect(LayoutCycler.next(after: english.id, in: sources, excluding: [russian.id])?.id == german.id)
    }

    @Test func startsFromFirstWhenCurrentIsOutsideCycle() {
        #expect(LayoutCycler.next(after: russian.id, in: sources, excluding: [russian.id])?.id == english.id)
        #expect(LayoutCycler.next(after: nil, in: sources, excluding: [])?.id == english.id)
    }

    @Test func returnsNilWhenNothingToSwitchTo() {
        #expect(LayoutCycler.next(after: english.id, in: sources, excluding: [russian.id, german.id]) == nil)
        #expect(LayoutCycler.next(after: english.id, in: [], excluding: []) == nil)
    }
}

struct SettingsTests {
    private let rightCommand = Hotkey.modifierTap(ModifierTap(keys: [.command: .right]))

    @Test func activeBindingsSkipUnavailableSources() {
        var settings = Settings()
        settings.setHotkey(rightCommand, for: .select(sourceID: english.id))
        settings.setHotkey(.keyCombo(KeyCombo(keyCode: 18, modifiers: [.control])), for: .select(sourceID: german.id))
        settings.setHotkey(.keyCombo(KeyCombo(keyCode: 49, modifiers: [.option, .command])), for: .cycle)

        let active = settings.activeBindings(availableSourceIDs: [english.id])
        #expect(active.map(\.action) == [.select(sourceID: english.id), .cycle])
        #expect(settings.usesModifierTaps)
    }

    @Test func findsActionForTap() {
        var settings = Settings()
        settings.setHotkey(rightCommand, for: .select(sourceID: english.id))
        let available: Set = [english.id]
        #expect(settings.action(forTap: [PhysicalModifier(.command, .right)], availableSourceIDs: available) == .select(sourceID: english.id))
        #expect(settings.action(forTap: [PhysicalModifier(.command, .left)], availableSourceIDs: available) == nil)
        #expect(settings.action(forTap: [PhysicalModifier(.command, .right)], availableSourceIDs: []) == nil)
    }
}

struct SettingsStoreTests {
    private func makeStore() -> (SettingsStore, UserDefaults) {
        let suite = "SwaprTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return (SettingsStore(defaults: defaults), defaults)
    }

    @Test func roundTripsSettings() {
        let (store, _) = makeStore()
        var settings = Settings()
        settings.setHotkey(.modifierTap(ModifierTap(keys: [.shift: .either, .command: .either])), for: .select(sourceID: russian.id))
        settings.setHotkey(.keyCombo(KeyCombo(keyCode: 49, modifiers: [.option, .command])), for: .cycle)
        settings.cycleExcludedIDs = [german.id]
        settings.menuBarDisplay = .icon
        settings.hasCompletedOnboarding = true

        store.save(settings)
        #expect(store.load() == settings)
    }

    @Test func returnsDefaultsWhenEmptyOrCorrupt() {
        let (store, defaults) = makeStore()
        #expect(store.load() == Settings())
        defaults.set(Data("not json".utf8), forKey: "settings")
        #expect(store.load() == Settings())
    }

    @Test func toleratesMissingAndUnknownFields() {
        let (store, defaults) = makeStore()
        let json = #"{"version":1,"settings":{"menuBarDisplay":"hidden","futureOption":42}}"#
        defaults.set(Data(json.utf8), forKey: "settings")

        var expected = Settings()
        expected.menuBarDisplay = .hidden
        #expect(store.load() == expected)
    }
}
