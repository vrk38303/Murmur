import SwiftUI

/// Soft tinted disc with the contact's initial. Hue is derived deterministically
/// from the name string so the same person always gets the same color.
struct Avatar: View {
    let name: String
    var size: CGFloat = 44
    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var scheme

    private var initial: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "?" : String(trimmed.first!).uppercased()
    }

    private var hue: Double {
        var h: UInt64 = 0
        for c in name.unicodeScalars {
            h = (h &* 31 &+ UInt64(c.value)) % 360
        }
        return Double(h)
    }

    private var bg: Color {
        // Approximation of the JSX `oklch(...)` discs via HSL — close enough
        // visually without an oklch dependency.
        scheme == .dark
            ? Color(hue: hue / 360, saturation: 0.10, brightness: 0.30)
            : Color(hue: hue / 360, saturation: 0.20, brightness: 0.86)
    }

    private var fg: Color {
        scheme == .dark
            ? Color(hue: hue / 360, saturation: 0.18, brightness: 0.92)
            : Color(hue: hue / 360, saturation: 0.30, brightness: 0.32)
    }

    var body: some View {
        ZStack {
            Circle().fill(bg)
            Text(initial)
                .font(.system(size: size * 0.42, weight: .semibold))
                .tracking(-0.3)
                .foregroundStyle(fg)
        }
        .frame(width: size, height: size)
        .accessibilityLabel(Text(name))
    }
}
