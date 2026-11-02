import AppKit
import SwiftUI

/// First-launch introduction. Shown once; Settings is one click away.
struct WelcomeView: View {
    let onContinue: () -> Void

    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(spacing: 24) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)
                .accessibilityHidden(true)

            VStack(spacing: 6) {
                Text("Welcome to Swapr")
                    .font(.largeTitle.weight(.bold))
                Text("Switch keyboard layouts with shortcuts you choose.")
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 16) {
                Feature(
                    symbol: "command",
                    title: "A shortcut for each layout",
                    detail: "Tap a single modifier such as Right ⌘, or use a combination such as ⇧⌘ or ⌃⌥1."
                )
                Feature(
                    symbol: "arrow.triangle.2.circlepath",
                    title: "Or cycle through them",
                    detail: "One shortcut moves to the next layout."
                )
                Feature(
                    symbol: "lock.shield",
                    title: "Private by design",
                    detail: "Works offline. Never reads, records or sends what you type."
                )
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(cornerRadius: 16)

            Toggle("Launch Swapr at login", isOn: Binding(
                get: { model.launchAtLoginStatus == .enabled || model.launchAtLoginStatus == .requiresApproval },
                set: { model.setLaunchAtLogin($0) }
            ))
            .toggleStyle(.checkbox)

            Button(action: onContinue) {
                Text("Set Up Shortcuts")
                    .frame(maxWidth: .infinity)
            }
            .prominentButtonStyle()
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
        }
        .padding(.horizontal, 32)
        .padding(.top, 40)
        .padding(.bottom, 28)
        .frame(width: 460)
    }
}

private struct Feature: View {
    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).fontWeight(.semibold)
                Text(detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
