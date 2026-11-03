import Carbon
import Foundation
import Observation
import SwaprCore

/// Lists the keyboard input sources enabled in macOS, tracks the selected one and switches it.
/// Backed by the Text Input Sources (TIS) API, the only public API for this.
@MainActor @Observable
final class InputSourceService {
    private(set) var sources: [InputSource] = []
    private(set) var currentID: String?

    /// Called when the user adds or removes a layout.
    @ObservationIgnored var onSourcesChanged: (() -> Void)?

    @ObservationIgnored private var handles: [String: TISInputSource] = [:]
    @ObservationIgnored private var observers: [any NSObjectProtocol] = []

    private static let selectableTypes: Set<String> = [
        kTISTypeKeyboardLayout as String,
        kTISTypeKeyboardInputMode as String,
        kTISTypeKeyboardInputMethodWithoutModes as String,
    ]

    var availableIDs: Set<String> { Set(handles.keys) }
    var current: InputSource? { sources.first { $0.id == currentID } }

    init() {
        reloadSources()
        refreshCurrent()

        let center = DistributedNotificationCenter.default()
        observers = [
            center.addObserver(forName: Notification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String), object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.refreshCurrent() }
            },
            center.addObserver(forName: Notification.Name(kTISNotifyEnabledKeyboardInputSourcesChanged as String), object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated {
                    guard let self else { return }
                    self.reloadSources()
                    self.refreshCurrent()
                    self.onSourcesChanged?()
                }
            },
        ]
    }

    /// Returns `false` when the source is no longer available or macOS refused the switch.
    @discardableResult
    func select(_ id: String) -> Bool {
        if handles[id] == nil { reloadSources() }
        guard let source = handles[id] else { return false }
        let succeeded = TISSelectInputSource(source) == noErr
        refreshCurrent()
        return succeeded
    }

    private func reloadSources() {
        let filter = [
            kTISPropertyInputSourceCategory as String: kTISCategoryKeyboardInputSource as String,
            kTISPropertyInputSourceIsSelectCapable as String: true,
        ] as CFDictionary
        let list = TISCreateInputSourceList(filter, false)?.takeRetainedValue() as? [TISInputSource] ?? []

        var handles: [String: TISInputSource] = [:]
        var sources: [InputSource] = []
        for source in list {
            guard let type: String = source.value(for: kTISPropertyInputSourceType),
                  Self.selectableTypes.contains(type),
                  let id: String = source.value(for: kTISPropertyInputSourceID),
                  handles[id] == nil else { continue }
            let name: String = source.value(for: kTISPropertyLocalizedName) ?? id
            let languages: [String] = source.value(for: kTISPropertyInputSourceLanguages) ?? []
            handles[id] = source
            sources.append(InputSource(id: id, name: name, languages: languages))
        }
        self.handles = handles
        if sources != self.sources { self.sources = sources }
    }

    private func refreshCurrent() {
        let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue()
        let id: String? = source?.value(for: kTISPropertyInputSourceID)
        if id != currentID { currentID = id }
    }
}

private extension TISInputSource {
    func value<T>(for key: CFString) -> T? {
        guard let raw = TISGetInputSourceProperty(self, key) else { return nil }
        return Unmanaged<AnyObject>.fromOpaque(raw).takeUnretainedValue() as? T
    }
}
