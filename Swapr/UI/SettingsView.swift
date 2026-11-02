import AppKit
import SwiftUI
import SwaprCore

struct SettingsView: View {
    @Environment(AppModel.self) private var model

    private var sources: [InputSource] { model.inputSources.sources }

    var body: some View {
        Form {
            layoutsSection
            cycleSection
            if model.tapMonitorState == .needsPermission || model.tapMonitorState == .failed {
                permissionSection
            }
            generalSection
        }
        .formStyle(.grouped)
        .frame(width: 520, height: 600)
    }

    // MARK: Sections

    private var layoutsSection: some View {
        Section {
            ForEach(sources) { source in
                LabeledContent {
                    HotkeyField(action: .select(sourceID: source.id))
                } label: {
                    HStack(spacing: 8) {
                        LayoutBadge(code: source.shortCode, isCurrent: source.id == model.inputSources.currentID)
                        Text(source.name)
                    }
                }
            }
            if sources.count < 2 {
                LabeledContent("Add another layout in Keyboard settings to switch between them.") {
                    Button("Open Keyboard Settings…", action: KeyboardSettings.open)
                }
                .foregroundStyle(.secondary)
            }
        } header: {
            Text("Layouts")
        } footer: {
            Text("Click a field, then press a combination such as ⌃⌥1, or tap modifiers alone such as Right ⌘ or ⇧⌘. Single modifiers are side-specific; combinations of modifiers work with either side.")
                .foregroundStyle(.secondary)
                .font(.footnote)
        }
    }

    private var cycleSection: some View {
        Section {
            LabeledContent("Switch to next layout") {
                HotkeyField(action: .cycle)
            }
            if sources.count > 2 {
                ForEach(sources) { source in
                    Toggle(isOn: Binding(
                        get: { model.isInCycle(source.id) },
                        set: { model.setInCycle(source.id, $0) }
                    )) {
                        Text("Include \(source.name)")
                    }
                }
            }
        } header: {
            Text("Cycle")
        }
    }

    private var permissionSection: some View {
        Section {
            let isFailed = model.tapMonitorState == .failed
            Label {
                VStack(alignment: .leading, spacing: 4) {
                    Text(isFailed ? "Restart required" : "Input Monitoring access required")
                        .fontWeight(.semibold)
                    Text(isFailed
                        ? "Access is granted, but macOS applies it after Swapr restarts."
                        : "Modifier shortcuts such as Right ⌘ need it to notice modifier taps. Swapr never reads, stores or sends what you type. Key combinations work without it.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } icon: {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow)
            }
            HStack {
                Spacer()
                if isFailed {
                    Button("Restart Swapr", action: relaunch)
                } else {
                    Button("Open Privacy Settings…") { model.requestInputMonitoring() }
                }
            }
        } header: {
            Text("Permissions")
        }
    }

    private var generalSection: some View {
        Section {
            Toggle("Launch at login", isOn: Binding(
                get: { model.launchAtLoginStatus == .enabled || model.launchAtLoginStatus == .requiresApproval },
                set: { model.setLaunchAtLogin($0) }
            ))
            if model.launchAtLoginStatus == .requiresApproval {
                LabeledContent("Allow Swapr in System Settings › General › Login Items.") {
                    Button("Open Login Items…", action: LaunchAtLogin.openSystemSettings)
                }
                .foregroundStyle(.secondary)
            }
            if let error = model.launchAtLoginError {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.callout)
            }

            Picker("Show in menu bar", selection: Binding(
                get: { model.settings.menuBarDisplay },
                set: { model.setMenuBarDisplay($0) }
            )) {
                Text("Layout code").tag(MenuBarDisplay.layoutCode)
                Text("Icon").tag(MenuBarDisplay.icon)
                Text("Nothing").tag(MenuBarDisplay.hidden)
            }
            if model.settings.menuBarDisplay == .hidden {
                Text("To open this window later, launch Swapr again from Applications or Spotlight.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            LabeledContent("Version", value: Self.version)
            HStack {
                Spacer()
                Button("Quit Swapr") { NSApp.terminate(nil) }
            }
        } header: {
            Text("General")
        }
    }

    // MARK: Helpers

    private static var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "\(short) (\(build))"
    }

    private func relaunch() {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.createsNewApplicationInstance = true
        NSWorkspace.shared.openApplication(at: Bundle.main.bundleURL, configuration: configuration) { _, error in
            guard error == nil else { return }
            Task { @MainActor in NSApp.terminate(nil) }
        }
    }
}
