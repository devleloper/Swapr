#if DEBUG
import AppKit
import SwiftUI

/// `Swapr --snapshot <directory>` renders the app's windows to PNG in light and dark
/// appearance, then quits. Rendering is offscreen, so no Screen Recording permission is needed.
@MainActor
enum DebugSnapshots {
    static func runIfRequested(model: AppModel) -> Bool {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "--snapshot"), index + 1 < arguments.count else { return false }
        let directory = URL(fileURLWithPath: arguments[index + 1], isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let screens: [(name: String, title: String, view: AnyView)] = [
            ("welcome", "", AnyView(WelcomeView {}.environment(model))),
            ("settings", "Swapr Settings", AnyView(SettingsView().environment(model))),
        ]
        let appearances: [(name: String, appearance: NSAppearance?)] = [
            ("light", NSAppearance(named: .aqua)),
            ("dark", NSAppearance(named: .darkAqua)),
        ]

        var windows: [(NSWindow, URL)] = []
        for screen in screens {
            for appearance in appearances {
                let controller = NSHostingController(rootView: screen.view)
                controller.sizingOptions = []
                let window = NSWindow(contentRect: .zero, styleMask: [.titled, .closable], backing: .buffered, defer: false)
                window.isReleasedWhenClosed = false
                window.appearance = appearance.appearance
                window.title = screen.title
                window.contentViewController = controller
                window.setContentSize(controller.view.fittingSize)
                window.setFrameOrigin(NSPoint(x: -20_000, y: -20_000))
                window.orderFrontRegardless()
                windows.append((window, directory.appendingPathComponent("\(screen.name)-\(appearance.name).png")))
            }
        }

        // Let SwiftUI finish layout and rendering before capturing.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            for (window, url) in windows {
                capture(window, to: url)
                window.close()
            }
            NSApp.terminate(nil)
        }
        return true
    }

    private static func capture(_ window: NSWindow, to url: URL) {
        guard let frameView = window.contentView?.superview,
              let bitmap = frameView.bitmapImageRepForCachingDisplay(in: frameView.bounds) else { return }
        frameView.cacheDisplay(in: frameView.bounds, to: bitmap)
        try? bitmap.representation(using: .png, properties: [:])?.write(to: url)
    }
}
#endif
