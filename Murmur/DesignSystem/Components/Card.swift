import SwiftUI

/// A grouped surface card used throughout call detail and settings. Optional
/// kicker title with an accent dot.
struct Card<Content: View>: View {
    var title: LocalizedStringKey?
    var accent: Color?
    @ViewBuilder var content: Content
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title {
                HStack(spacing: 8) {
                    if let accent {
                        Circle().fill(accent).frame(width: 6, height: 6)
                    }
                    Text(title)
                        .mmKicker(color: theme.ink2)
                        .tracking(1.2)
                }
            }
            content
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(theme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(theme.cardEdge, lineWidth: 0.5)
                )
        )
    }
}
