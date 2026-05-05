import SwiftUI

struct MindMapView: View {
    @Environment(\.services) private var services
    @State private var vm: MindMapViewModel?

    var body: some View {
        ScreenShell(topInset: 54) {
            if let vm {
                content(vm: vm)
            }
        }
        .task {
            if vm == nil { vm = MindMapViewModel(services: services) }
            await vm?.load()
        }
    }

    @ViewBuilder
    private func content(vm: MindMapViewModel) -> some View {
        VStack(spacing: 0) {
            chrome(vm: vm)
            ZStack(alignment: .bottomLeading) {
                MindMapCanvas(graph: vm.graph,
                              peeked: Binding(
                                get: { vm.peeked },
                                set: { vm.peeked = $0 }
                              ))
                .padding(.top, 8)

                if let node = vm.peeked {
                    PeekCard(node: node)
                        .transition(.scale.combined(with: .opacity))
                        .padding(.leading, 30)
                        .padding(.bottom, 100)
                }
            }
            .padding(.bottom, 86)
        }
    }

    private func chrome(vm: MindMapViewModel) -> some View {
        HStack {
            HStack(spacing: 8) {
                ForEach(MindMapFilter.allCases, id: \.self) { f in
                    Button {
                        vm.filter = f
                        Task { await vm.load() }
                    } label: {
                        Text(f.label)
                            .font(.system(size: 13,
                                          weight: vm.filter == f ? .semibold : .regular))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                vm.filter == f
                                ? AnyShapeStyle(.regularMaterial)
                                : AnyShapeStyle(.clear)
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            Spacer()
            Button { } label: {
                ZStack {
                    Circle().fill(.regularMaterial)
                    MMIconView(icon: .search, size: 18)
                }
                .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }
}

private struct PeekCard: View {
    let node: MindMapNode
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(node.label.uppercased())
                .font(.system(size: 11, weight: .bold))
                .tracking(1)
                .foregroundStyle(theme.ink3)
            Text(node.type == .call
                 ? "Conversation captured."
                 : "Topic across \(node.importance) calls.")
                .font(.system(size: 13))
                .foregroundStyle(theme.ink2)
                .lineSpacing(2)
            Text("\(node.importance) call\(node.importance == 1 ? "" : "s")")
                .font(.system(size: 12))
                .foregroundStyle(theme.ink3)
                .padding(.top, 2)
        }
        .padding(14)
        .frame(width: 200, alignment: .leading)
        .background(theme.card, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(theme.cardEdge, lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.18), radius: 16, y: 8)
    }
}
