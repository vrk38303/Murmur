import SwiftUI

/// Tall ink button used in onboarding and primary CTAs.
struct PrimaryButton: View {
    let title: LocalizedStringKey
    var action: () -> Void
    @Environment(\.theme) private var theme

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .tracking(-0.2)
                .foregroundStyle(theme.bg)
                .frame(maxWidth: .infinity, minHeight: 54)
                .background(
                    RoundedRectangle(cornerRadius: 14).fill(theme.ink)
                )
        }
        .buttonStyle(.plain)
    }
}

/// Round accent FAB used as the "+" in the calls header.
struct AccentCircleButton: View {
    let icon: MMIcon
    var size: CGFloat = 38
    var action: () -> Void
    @Environment(\.theme) private var theme

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle().fill(theme.accent)
                MMIconView(icon: icon, size: size * 0.52, color: .white, weight: 2.4)
            }
            .frame(width: size, height: size)
            .shadow(color: theme.accentSoft, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Start a recording"))
    }
}
