import SwiftUI

/// Compact layout code, e.g. `EN`, highlighted for the active layout.
struct LayoutBadge: View {
    let code: String
    var isCurrent = false

    var body: some View {
        Text(code)
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .foregroundStyle(isCurrent ? Color.white : Color.secondary)
            .frame(minWidth: 28, minHeight: 18)
            .padding(.horizontal, 2)
            .background(isCurrent ? Color.accentColor : Color.secondary.opacity(0.15), in: .rect(cornerRadius: 5))
            .accessibilityLabel(isCurrent ? "\(code), current layout" : code)
    }
}

extension View {
    /// Liquid Glass on macOS 26 and later, a material elsewhere.
    @ViewBuilder
    func glassCard(cornerRadius: CGFloat) -> some View {
        if #available(macOS 26, *) {
            glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
        } else {
            background(.regularMaterial, in: .rect(cornerRadius: cornerRadius))
        }
    }

    @ViewBuilder
    func prominentButtonStyle() -> some View {
        if #available(macOS 26, *) {
            buttonStyle(.glassProminent)
        } else {
            buttonStyle(.borderedProminent)
        }
    }
}
