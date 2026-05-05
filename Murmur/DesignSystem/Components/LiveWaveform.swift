import SwiftUI

/// Live waveform driven by an external level stream (RMS 0…1). Each bar
/// animates between heights with a 90 ms ease.
struct LiveWaveform: View {
    let levels: [CGFloat]
    var color: Color
    var barWidth: CGFloat = 4
    var gap: CGFloat = 4
    var maxHeight: CGFloat = 80
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(alignment: .center, spacing: gap) {
            ForEach(Array(levels.enumerated()), id: \.offset) { _, h in
                RoundedRectangle(cornerRadius: barWidth / 2)
                    .fill(color.opacity(0.85))
                    .frame(width: barWidth, height: max(2, h * maxHeight))
                    .animation(reduceMotion ? nil : .easeOut(duration: 0.09),
                               value: h)
            }
        }
        .frame(height: maxHeight)
        .accessibilityLabel("Live audio level")
    }
}
