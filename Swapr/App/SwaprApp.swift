import AppKit
import SwiftUI

@main
struct SwaprApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        let model = appDelegate.model
        MenuBarExtra(isInserted: Binding(
            get: { model.settings.menuBarDisplay != .hidden },
            // macOS removes the item when the user ⌘-drags it out of the menu bar.
            set: { if !$0 { model.setMenuBarDisplay(.hidden) } }
        )) {
            MenuBarMenu(model: model, windows: appDelegate.windows)
        } label: {
            MenuBarLabel(model: model)
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let model = AppModel()
    private(set) lazy var windows = WindowPresenter(model: model)

    func applicationDidFinishLaunching(_ notification: Notification) {
        model.start()
        #if DEBUG
        if DebugSnapshots.runIfRequested(model: model) { return }
        #endif
        if !model.settings.hasCompletedOnboarding {
            windows.showWelcome()
        }
    }

    /// Reopening the app from Finder or Spotlight shows Settings,
    /// the way back in when the menu bar item is hidden.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        windows.showSettings()
        return false
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        model.refreshSystemState()
    }
}
