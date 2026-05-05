import SwiftUI

/// Sets the screen background, default font, and switches the theme to match
/// the resolved color scheme. Every screen wraps its body in this.
struct ScreenShell<Content: View>: View {
    var topInset: CGFloat = 0
    @ViewBuilder var content: Content
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let theme: MurmurTheme = (scheme == .dark) ? .dark : .light
        ZStack(alignment: .top) {
            theme.bg.ignoresSafeArea()
            content
                .padding(.top, topInset)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .foregroundStyle(theme.ink)
        .murmurTheme(theme)
    }
}
