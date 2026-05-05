import SwiftUI

struct StartRecordingSheet: View {
    var onCancel: () -> Void
    var onStart: () -> Void
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            // grabber
            Capsule().fill(theme.ink4).frame(width: 36, height: 5)
                .padding(.top, 12).padding(.bottom, 16)

            VStack(alignment: .leading, spacing: 6) {
                Text("rec.sheet.kicker").mmKicker(color: theme.ink3)
                Text("rec.sheet.title")
                    .font(.system(size: 22, weight: .bold))
                    .tracking(-0.4)
                    .padding(.top, 6)
                Text("rec.sheet.body")
                    .font(.system(size: 15))
                    .foregroundStyle(theme.ink2)
                    .lineSpacing(3)
                    .padding(.top, 8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)

            // Big record dot
            Button(action: onStart) {
                ZStack {
                    Circle().fill(theme.rec)
                        .frame(width: 92, height: 92)
                        .overlay(
                            Circle().stroke(theme.bg, lineWidth: 4)
                        )
                        .shadow(color: theme.rec.opacity(0.35), radius: 16, y: 12)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Start recording")
            .padding(.vertical, 28)

            HStack(spacing: 6) {
                Text("rec.sheet.why")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.accent)
                Text("·")
                Text("rec.sheet.primer").font(.system(size: 13))
            }
            .foregroundStyle(theme.ink3)
            .padding(.bottom, 36)
        }
        .frame(maxWidth: .infinity)
        .background(theme.bg)
        .clipShape(UnevenRoundedRectangle(cornerRadii: .init(
            topLeading: 28, topTrailing: 28
        )))
    }
}
