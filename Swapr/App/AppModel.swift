import AppKit
import Observation
import ServiceManagement
import SwaprCore

/// Application state and behavior: owns settings and wires hotkey sources to layout switching.
@MainActor @Observable
final class AppModel {
    enum TapMonitorState: Equatable {
        /// No modifier-tap shortcut is configured.
        case notNeeded
        case running
        /// Waiting for the user to grant Input Monitoring.
        case needsPermission
        /// Permission is granted but macOS still refused the tap; a relaunch usually fixes it.
        case failed
    }

    let inputSources = InputSourceService()
    private(set) var settings: Settings
    private(set) var failedActions: Set<HotkeyAction> = []
    private(set) var tapMonitorState: TapMonitorState = .notNeeded
    private(set) var launchAtLoginStatus: SMAppService.Status = .notRegistered
    private(set) var launchAtLoginError: String?

    @ObservationIgnored private let store = SettingsStore()
    @ObservationIgnored private let keyCombos = KeyComboHotkeys()
    @ObservationIgnored private let tapMonitor = ModifierTapMonitor()
    @ObservationIgnored private var validator = HotkeyValidator(systemShortcuts: [])
    @ObservationIgnored private var isRecording = false
    @ObservationIgnored private var permissionPoll: Timer?

    init() {
        settings = store.load()
    }

    var needsAttention: Bool {
        !failedActions.isEmpty || tapMonitorState == .needsPermission || tapMonitorState == .failed
    }

    func start() {
        keyCombos.onTrigger = { [weak self] action in self?.perform(action) }
        tapMonitor.onTap = { [weak self] keys in self?.handleTap(keys) }
        inputSources.onSourcesChanged = { [weak self] in self?.applyHotkeys() }
        refreshSystemState()
    }

    /// Re-reads state that the user can change outside the app. Called on launch and activation.
    func refreshSystemState() {
        validator = HotkeyValidator(systemShortcuts: SystemShortcuts.enabled())
        launchAtLoginStatus = LaunchAtLogin.status
        applyHotkeys()
    }

    // MARK: Switching

    func perform(_ action: HotkeyAction) {
        let targetID: String? = switch action {
        case .select(let id):
            id
        case .cycle:
            LayoutCycler.next(after: inputSources.currentID, in: inputSources.sources, excluding: settings.cycleExcludedIDs)?.id
        }
        guard let targetID, targetID != inputSources.currentID else { return }
        if !inputSources.select(targetID) {
            NSSound.beep()
        }
    }

    private func handleTap(_ keys: Set<PhysicalModifier>) {
        guard let action = settings.action(forTap: keys, availableSourceIDs: inputSources.availableIDs) else { return }
        perform(action)
    }

    // MARK: Settings

    /// Validates and stores a hotkey; `nil` clears it.
    func setHotkey(_ hotkey: Hotkey?, for action: HotkeyAction) -> HotkeyValidationError? {
        if let hotkey, let error = validator.validate(hotkey, for: action, in: settings) {
            return error
        }
        update { $0.setHotkey(hotkey, for: action) }
        return nil
    }

    func isInCycle(_ sourceID: String) -> Bool {
        !settings.cycleExcludedIDs.contains(sourceID)
    }

    func setInCycle(_ sourceID: String, _ included: Bool) {
        update {
            if included { $0.cycleExcludedIDs.remove(sourceID) } else { $0.cycleExcludedIDs.insert(sourceID) }
        }
    }

    func setMenuBarDisplay(_ display: MenuBarDisplay) {
        update { $0.menuBarDisplay = display }
    }

    func completeOnboarding() {
        update { $0.hasCompletedOnboarding = true }
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            try LaunchAtLogin.setEnabled(enabled)
            launchAtLoginError = nil
        } catch {
            launchAtLoginError = error.localizedDescription
        }
        launchAtLoginStatus = LaunchAtLogin.status
    }

    /// Global hotkeys are suspended while a shortcut field records, so the keys reach the field.
    func setRecording(_ recording: Bool) {
        guard recording != isRecording else { return }
        isRecording = recording
        applyHotkeys()
    }

    func requestInputMonitoring() {
        if !InputMonitoring.request() {
            InputMonitoring.openSystemSettings()
        }
    }

    // MARK: Display

    func label(for hotkey: Hotkey) -> String {
        HotkeyFormatter.string(for: hotkey, characterName: KeyNames.character(for:))
    }

    func title(for action: HotkeyAction) -> String {
        switch action {
        case .select(let id): inputSources.sources.first { $0.id == id }?.name ?? "a disabled layout"
        case .cycle: "Next Layout"
        }
    }

    // MARK: Hotkey registration

    private func update(_ change: (inout Settings) -> Void) {
        var updated = settings
        change(&updated)
        guard updated != settings else { return }
        settings = updated
        store.save(updated)
        applyHotkeys()
    }

    private func applyHotkeys() {
        guard !isRecording else {
            keyCombos.unregisterAll()
            tapMonitor.stop()
            return
        }

        let bindings = settings.activeBindings(availableSourceIDs: inputSources.availableIDs)
        let combos = bindings.compactMap { binding -> (combo: KeyCombo, action: HotkeyAction)? in
            if case .keyCombo(let combo) = binding.hotkey { (combo, binding.action) } else { nil }
        }
        let failed = keyCombos.register(combos)
        if failed != failedActions { failedActions = failed }

        let needsTaps = bindings.contains { if case .modifierTap = $0.hotkey { true } else { false } }
        updateTapMonitor(needed: needsTaps)
    }

    private func updateTapMonitor(needed: Bool) {
        let state: TapMonitorState
        if !needed {
            tapMonitor.stop()
            state = .notNeeded
        } else if !InputMonitoring.isGranted {
            tapMonitor.stop()
            state = .needsPermission
        } else {
            state = tapMonitor.start() ? .running : .failed
        }
        if state != tapMonitorState { tapMonitorState = state }
        updatePermissionPolling()
    }

    /// While access is missing, check every few seconds so shortcuts start working as soon
    /// as the user flips the switch in System Settings, without having to come back to Swapr.
    private func updatePermissionPolling() {
        if tapMonitorState == .needsPermission {
            guard permissionPoll == nil else { return }
            permissionPoll = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
                MainActor.assumeIsolated {
                    guard let self, InputMonitoring.isGranted else { return }
                    self.applyHotkeys()
                }
            }
        } else {
            permissionPoll?.invalidate()
            permissionPoll = nil
        }
    }
}
