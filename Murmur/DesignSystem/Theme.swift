import SwiftUI

/// Murmur's theme. Light is warm ivory paper; dark is warm charcoal — designed
/// independently per the design package, not an inversion of light.
struct MurmurTheme: Equatable {
    let bg: Color
    let bgGrouped: Color
    let card: Color
    let cardEdge: Color
    let sep: Color
    let sepStrong: Color
    let ink: Color
    let ink2: Color
    let ink3: Color
    let ink4: Color
    let accent: Color
    let accentSoft: Color
    let rec: Color
    let success: Color
    let node: Color
    let nodeText: Color
    let edge: Color

    static let light = MurmurTheme(
        bg:        Color(hex: 0xF6F2EA),
        bgGrouped: Color(hex: 0xEFE9DD),
        card:      Color(hex: 0xFFFDF7),
        cardEdge:  Color(hex: 0x281E0F, opacity: 0.06),
        sep:       Color(hex: 0x281E0F, opacity: 0.10),
        sepStrong: Color(hex: 0x281E0F, opacity: 0.18),
        ink:       Color(hex: 0x15110A),
        ink2:      Color(hex: 0x15110A, opacity: 0.62),
        ink3:      Color(hex: 0x15110A, opacity: 0.40),
        ink4:      Color(hex: 0x15110A, opacity: 0.22),
        accent:    Color(hex: 0x1F4FE0),
        accentSoft: Color(hex: 0x1F4FE0, opacity: 0.12),
        rec:       Color(hex: 0xD7372F),
        success:   Color(hex: 0x2F8F5C),
        node:      Color(hex: 0x15110A),
        nodeText:  Color(hex: 0xF6F2EA),
        edge:      Color(hex: 0x15110A, opacity: 0.22)
    )

    static let dark = MurmurTheme(
        bg:        Color(hex: 0x0A0908),
        bgGrouped: Color(hex: 0x15130F),
        card:      Color(hex: 0x1C1A15),
        cardEdge:  Color(hex: 0xFFFAEB, opacity: 0.06),
        sep:       Color(hex: 0xFFFAEB, opacity: 0.10),
        sepStrong: Color(hex: 0xFFFAEB, opacity: 0.18),
        ink:       Color(hex: 0xF6F2EA),
        ink2:      Color(hex: 0xF6F2EA, opacity: 0.62),
        ink3:      Color(hex: 0xF6F2EA, opacity: 0.40),
        ink4:      Color(hex: 0xF6F2EA, opacity: 0.22),
        accent:    Color(hex: 0x5C82F5),
        accentSoft: Color(hex: 0x5C82F5, opacity: 0.18),
        rec:       Color(hex: 0xFF4438),
        success:   Color(hex: 0x3DD37A),
        node:      Color(hex: 0xF6F2EA),
        nodeText:  Color(hex: 0x0A0908),
        edge:      Color(hex: 0xF6F2EA, opacity: 0.22)
    )
}

private struct MurmurThemeKey: EnvironmentKey {
    static let defaultValue: MurmurTheme = .light
}

extension EnvironmentValues {
    var theme: MurmurTheme {
        get { self[MurmurThemeKey.self] }
        set { self[MurmurThemeKey.self] = newValue }
    }
}

extension View {
    func murmurTheme(_ theme: MurmurTheme) -> some View {
        environment(\.theme, theme)
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}
