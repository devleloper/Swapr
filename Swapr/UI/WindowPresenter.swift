import AppKit
import SwiftUI

/// Shows the single app window (Welcome or Settings) on demand and releases it on close,
/// so an idle menu bar app keeps no view hierarchy in memory.
@MainActor
final class WindowPresenter: NSObject, NSWindowDelegate {
    private let model: AppModel
    private var window: NSWindow?
    private var isShowingWelcome = false

    init(model: AppModel) {
        self.model = model
    }

    func showSettings() {
        isShowingWelcome = false
        present(SettingsView(), title: "Swapr Settings", transparentTitlebar: false)
    }

    func showWelcome() {
        isShowingWelcome = true
        present(WelcomeView { [weak self] in
            self?.model.completeOnboarding()
            self?.showSettings()
        }, title: "Welcome to Swapr", transparentTitlebar: true)
    }

    func windowWillClose(_ notification: Notification) {
        if isShowingWelcome {
            model.completeOnboarding()
        }
        window?.contentViewController = nil
        window = nil
    }

    private func present(_ content: some View, title: String, transparentTitlebar: Bool) {
        let controller = NSHostingController(rootView: content.environment(model))
        // Both screens have a fixed layout: size the window once instead of letting the
        // hosting controller drive it continuously (which can loop Auto Layout).
        controller.sizingOptions = []

        let isNew = window == nil
        let window = window ?? makeWindow()
        window.contentViewController = controller
        window.setContentSize(controller.view.fittingSize)
        window.title = title
        window.titlebarAppearsTransparent = transparentTitlebar
        window.titleVisibility = transparentTitlebar ? .hidden : .visible
        if isNew {
            window.center()
            self.window = window
        }

        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }

    private func makeWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: .zero,
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.delegate = self
        return window
    }
}
