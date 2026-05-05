import SwiftUI

struct ProcessingView: View {
    let progress: ProcessingProgress
    var onDone: () -> Void
    @State private var spin: Double = 0
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            ZStack {
                Circle().fill(theme.bgGrouped)
                MMIconView(icon: .cpu, size: 28, color: theme.accent, weight: 1.8)
            }
            .frame(width: 64, height: 64)
            .rotationEffect(.degrees(spin))
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    spin = 360
                }
            }

            Text("rec.proc.title")
                .font(.system(size: 20, weight: .semibold))
                .tracking(-0.3)
            Text("rec.proc.body")
                .font(.system(size: 14))
                .foregroundStyle(theme.ink2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 240)
                .lineSpacing(2)
                .padding(.bottom, 8)

            VStack(alignment: .leading, spacing: 8) {
                step("rec.proc.transcribed", done: progress.transcribed)
                step("rec.proc.summarized",  done: progress.summarized)
                step("rec.proc.linked",      done: progress.linkedToMap)
            }
            .frame(maxWidth: 240, alignment: .leading)
            .padding(.top, 16)

            Spacer()
            if progress.linkedToMap {
                PrimaryButton(title: "Done", action: onDone)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 50)
            }
        }
        .padding(40)
    }

    private func step(_ label: LocalizedStringKey, done: Bool) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .stroke(done ? Color.clear : theme.ink4, lineWidth: 1.5)
                if done {
                    Circle().fill(theme.success)
                    MMIconView(icon: .check, size: 12, color: .white, weight: 2.6)
                }
            }
            .frame(width: 18, height: 18)
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(done ? theme.ink : theme.ink3)
        }
    }
}
