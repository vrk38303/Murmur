import SwiftUI

enum MMTab: String, CaseIterable, Hashable {
    case calls, map, settings

    var label: LocalizedStringKey {
        switch self {
        case .calls:    return "tab.calls"
        case .map:      return "tab.map"
        case .settings: return "tab.settings"
        }
    }

    var icon: MMIcon {
        switch self {
        case .calls:    return .waveform
        case .map:      return .map
        case .settings: return .gear
        }
    }
}

struct MurmurTabBar: View {
    @Binding var active: MMTab
    var onTap: ((MMTab) -> Void)? = nil
    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MMTab.allCases, id: \.self) { tab in
                Button {
                    active = tab
                    onTap?(tab)
                } label: {
                    let on = active == tab
                    let c = on ? theme.accent : theme.ink3
                    VStack(spacing: 3) {
                        MMIconView(icon: tab.icon, size: 24, color: c,
                                   weight: on ? 2.2 : 1.8)
                        Text(tab.label)
                            .font(.system(size: 10, weight: on ? .semibold : .medium))
                            .foregroundStyle(c)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                    .padding(.bottom, 28) // mimic safe-area inset
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.label)
                .accessibilityAddTraits(active == tab ? [.isSelected] : [])
            }
        }
        .background(
            (scheme == .dark ? theme.bg.opacity(0.82) : theme.bg.opacity(0.82))
                .background(.ultraThinMaterial)
        )
        .overlay(Rectangle().fill(theme.sep).frame(height: 0.5),
                 alignment: .top)
    }
}
