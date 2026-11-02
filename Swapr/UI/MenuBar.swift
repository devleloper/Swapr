import AppKit
import SwiftUI

struct MenuBarLabel: View {
    let model: AppModel

    var body: some View {
        switch model.settings.menuBarDisplay {
        case .layoutCode:
            Text(model.inputSources.current?.shortCode ?? "—")
        case .icon, .hidden:
            Image(systemName: "keyboard")
        }
    }
}

struct MenuBarMenu: View {
    let model: AppModel
    let windows: WindowPresenter

    var body: some View {
        ForEach(model.inputSources.sources) { source in
            Toggle(source.name, isOn: Binding(
                get: { model.inputSources.currentID == source.id },
                set: { _ in model.perform(.select(sourceID: source.id)) }
            ))
        }

        Divider()

        if model.needsAttention {
            Button("Shortcuts Need Attention…") { windows.showSettings() }
        }
        Button("Settings…") { windows.showSettings() }
            .keyboardShortcut(",")

        Divider()

        Button("Quit Swapr") { NSApp.terminate(nil) }
            .keyboardShortcut("q")
    }
}
