import SwiftUI

/// Typography scale derived from the design package's "Type" sheet.
/// Sizes mirror the JSX prototype 1:1; weights map to SF Pro defaults.
/// All sizes are scaled by Dynamic Type via `.dynamicTypeSize` callers.
enum MMType {
    static let largeTitle = Font.system(size: 34, weight: .bold, design: .default)
    static let title2     = Font.system(size: 22, weight: .bold, design: .default)
    static let title3     = Font.system(size: 26, weight: .bold, design: .default)
    static let headline   = Font.system(size: 17, weight: .semibold, design: .default)
    static let body       = Font.system(size: 17, weight: .regular, design: .default)
    static let body16     = Font.system(size: 16, weight: .regular, design: .default)
    static let bodyEmph   = Font.system(size: 16, weight: .semibold, design: .default)
    static let callout    = Font.system(size: 15, weight: .regular, design: .default)
    static let footnote   = Font.system(size: 13, weight: .regular, design: .default)
    static let caption    = Font.system(size: 12, weight: .regular, design: .default)
    static let kicker     = Font.system(size: 11, weight: .bold, design: .default)
    static let timer      = Font.system(size: 56, weight: .light, design: .default)
        .monospacedDigit()
    static let nodeLarge  = Font.system(size: 14, weight: .bold)
    static let nodeSmall  = Font.system(size: 11, weight: .medium)
    static let display    = Font.system(size: 48, weight: .bold)
}

extension Text {
    /// Mimic the kicker style: 11pt, 1.4 letter spacing, uppercase.
    func mmKicker(color: Color) -> some View {
        self
            .font(MMType.kicker)
            .tracking(1.4)
            .textCase(.uppercase)
            .foregroundStyle(color)
    }
}
