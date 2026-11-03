import AppKit
import SwiftUI
import SwaprCore

/// Records a key combination or a modifier-only tap.
/// ⌫ clears, Esc cancels, a click elsewhere ends recording.
struct HotkeyField: View {
    let action: HotkeyAction

    @Environment(AppModel.self) private var model
    @State private var session = RecordingSession()
    @State private var error: HotkeyValidationError?

    private var hotkey: Hotkey? { model.settings.hotkey(for: action) }

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            HStack(spacing: 6) {
                if hotkey != nil, !session.isRecording {
                    Button {
                        error = nil
                        _ = model.setHotkey(nil, for: action)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                    .help("Remove shortcut")
                    .accessibilityLabel("Remove shortcut for \(model.title(for: action))")
                }

                Button {
                    error = nil
                    session.start()
                } label: {
                    Text(displayText)
                        .foregroundStyle(session.isRecording ? Color.accentColor : (hotkey == nil ? .secondary : .primary))
                        .frame(minWidth: 120)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 10)
                        .background(.quaternary.opacity(0.6), in: .rect(cornerRadius: 6))
                        .overlay {
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(session.isRecording ? Color.accentColor : .clear, lineWidth: 1.5)
                        }
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .help("Press a key combination such as ⌃⌥1, or tap modifiers alone such as Right ⌘ or ⇧⌘. ⌫ clears, Esc cancels.")
                .accessibilityLabel("Shortcut for \(model.title(for: action))")
                .accessibilityValue(hotkey.map(model.label(for:)) ?? "None")
            }

            if let message {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.trailing)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .onAppear {
            session.onRecordingChange = { [model] recording in model.setRecording(recording) }
            session.onOutcome = { outcome in handle(outcome) }
        }
        .onDisappear { session.stop() }
    }

    private var displayText: String {
        if session.isRecording { return "Type Shortcut…" }
        return hotkey.map(model.label(for:)) ?? "Record Shortcut"
    }

    private var message: String? {
        if let error { return describe(error) }
        if model.failedActions.contains(action) {
            return "Couldn’t register this shortcut. Another app may be using it."
        }
        return nil
    }

    private func handle(_ outcome: HotkeyRecorder.Outcome) {
        switch outcome {
        case .recorded(let hotkey):
            error = model.setHotkey(hotkey, for: action)
        case .cleared:
            error = nil
            _ = model.setHotkey(nil, for: action)
        case .cancelled:
            error = nil
        }
    }

    private func describe(_ error: HotkeyValidationError) -> String {
        switch error {
        case .requiresModifier:
            "Add ⌘, ⌃ or ⌥, or use a function key."
        case .optionOrShiftOnly:
            "Add ⌘ or ⌃. ⌥ and ⇧ alone are used for typing characters."
        case .duplicate(let other):
            "Already used for \(model.title(for: other))."
        case .reservedBySystem:
            "Used by macOS. Change it in System Settings › Keyboard › Keyboard Shortcuts."
        }
    }
}

/// Captures key events for one recording while a Swapr window is key.
/// A local event monitor needs no permission and sees no events from other apps.
@MainActor @Observable
private final class RecordingSession {
    private(set) var isRecording = false

    @ObservationIgnored var onOutcome: ((HotkeyRecorder.Outcome) -> Void)?
    @ObservationIgnored var onRecordingChange: ((Bool) -> Void)?
    @ObservationIgnored private var monitor: Any?
    @ObservationIgnored private var resignObserver: (any NSObjectProtocol)?
    @ObservationIgnored private var recorder = HotkeyRecorder()

    func start() {
        guard !isRecording else { return }
        recorder = HotkeyRecorder()
        isRecording = true
        onRecordingChange?(true)
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged, .leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self else { return event }
            return MainActor.assumeIsolated { self.handle(event) } ? nil : event
        }
        // Switching to another app mid-recording would otherwise leave global hotkeys suspended.
        resignObserver = NotificationCenter.default.addObserver(forName: NSWindow.didResignKeyNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.stop() }
        }
    }

    func stop() {
        guard isRecording else { return }
        if let monitor { NSEvent.removeMonitor(monitor) }
        if let resignObserver { NotificationCenter.default.removeObserver(resignObserver) }
        monitor = nil
        resignObserver = nil
        isRecording = false
        onRecordingChange?(false)
    }

    /// Returns `true` when the event was consumed.
    private func handle(_ event: NSEvent) -> Bool {
        switch event.type {
        case .keyDown:
            guard !event.isARepeat else { return true }
            let modifiers = ModifierFlags(cocoaFlags: event.modifierFlags.rawValue)
            finish(recorder.keyDown(keyCode: event.keyCode, modifiers: modifiers))
            return true
        case .flagsChanged:
            let pressed = PhysicalModifier.pressed(inRawFlags: UInt64(event.modifierFlags.rawValue))
            if let outcome = recorder.modifiersChanged(to: pressed, at: event.timestamp) {
                finish(outcome)
            }
            return true
        default:
            // A click ends recording but is still delivered.
            stop()
            return false
        }
    }

    private func finish(_ outcome: HotkeyRecorder.Outcome) {
        stop()
        onOutcome?(outcome)
    }
}
