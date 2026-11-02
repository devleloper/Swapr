import Carbon
import SwaprCore

/// Global key-combination hotkeys via Carbon's `RegisterEventHotKey`.
/// It is still the only public API for system-wide shortcuts that needs no permissions.
@MainActor
final class KeyComboHotkeys {
    var onTrigger: ((HotkeyAction) -> Void)?

    private static let signature: OSType = 0x5357_5052 // 'SWPR'
    private var handler: EventHandlerRef?
    private var registered: [UInt32: (ref: EventHotKeyRef, action: HotkeyAction)] = [:]

    /// Replaces all registrations. Returns the actions whose hotkey could not be registered.
    func register(_ combos: [(combo: KeyCombo, action: HotkeyAction)]) -> Set<HotkeyAction> {
        unregisterAll()
        guard !combos.isEmpty else { return [] }
        guard installHandlerIfNeeded() else { return Set(combos.map(\.action)) }

        var failed: Set<HotkeyAction> = []
        for (index, entry) in combos.enumerated() {
            let id = UInt32(index + 1)
            var ref: EventHotKeyRef?
            let status = RegisterEventHotKey(
                UInt32(entry.combo.keyCode),
                entry.combo.modifiers.carbonFlags,
                EventHotKeyID(signature: Self.signature, id: id),
                GetApplicationEventTarget(),
                0,
                &ref
            )
            if status == noErr, let ref {
                registered[id] = (ref, entry.action)
            } else {
                failed.insert(entry.action)
            }
        }
        return failed
    }

    func unregisterAll() {
        for entry in registered.values {
            UnregisterEventHotKey(entry.ref)
        }
        registered.removeAll()
    }

    fileprivate func handlePress(id: UInt32) {
        guard let action = registered[id]?.action else { return }
        onTrigger?(action)
    }

    /// The handler lives as long as the app; this object is owned by the app model for its whole lifetime.
    private func installHandlerIfNeeded() -> Bool {
        guard handler == nil else { return true }
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            hotKeyPressed,
            1,
            &spec,
            Unmanaged.passUnretained(self).toOpaque(),
            &handler
        )
        return status == noErr
    }
}

private func hotKeyPressed(_: EventHandlerCallRef?, event: EventRef?, userData: UnsafeMutableRawPointer?) -> OSStatus {
    guard let event, let userData else { return OSStatus(eventNotHandledErr) }
    var hotKeyID = EventHotKeyID()
    let status = GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotKeyID
    )
    guard status == noErr else { return status }
    let id = hotKeyID.id
    // Points at the hotkey center, which is only touched on the main actor below.
    nonisolated(unsafe) let center = userData
    // Carbon delivers application events on the main thread.
    MainActor.assumeIsolated {
        Unmanaged<KeyComboHotkeys>.fromOpaque(center).takeUnretainedValue().handlePress(id: id)
    }
    return noErr
}
