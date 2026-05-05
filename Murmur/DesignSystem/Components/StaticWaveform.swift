import SwiftUI

/// Deterministic stylised waveform, rendered as rounded bars. Used in the
/// calls list (small) and the call detail hero (large). Samples are seeded so
/// each call has a stable visual signature.
struct StaticWaveform: View {
    let samples: [CGFloat]
    var color: Color = .primary
    var barWidth: CGFloat = 2
    var gap: CGFloat = 2
    var opacity: Double = 0.85

    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
                guard !samples.isEmpty else { return }
                let total = CGFloat(samples.count) * (barWidth + gap) - gap
                let scale = size.width / total
                ctx.scaleBy(x: scale, y: 1)
                for (i, a) in samples.enumerated() {
                    let h = max(2, a * size.height * 0.9)
                    let x = CGFloat(i) * (barWidth + gap)
                    let rect = CGRect(x: x, y: (size.height - h) / 2,
                                      width: barWidth, height: h)
                    ctx.fill(Path(roundedRect: rect, cornerRadius: barWidth / 2),
                             with: .color(color.opacity(opacity)))
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .accessibilityHidden(true)
    }

    /// Match the JS `seedSamples` shape: gentle envelope plus seeded noise.
    static func seeded(_ seed: Int, count: Int = 120) -> [CGFloat] {
        var s = UInt64(bitPattern: Int64(seed))
        var arr: [CGFloat] = []
        arr.reserveCapacity(count)
        for i in 0..<count {
            s = (s &* 9301 &+ 49297) % 233280
            let r = Double(s) / 233280.0
            let env = sin(Double(i) / Double(count) * .pi) * 0.7 + 0.3
            arr.append(CGFloat(max(0.08, min(1.0, env * (0.5 + r * 0.6)))))
        }
        return arr
    }
}
