import SwiftUI

/// Renders the force-directed graph. Positions arrive in [0,1] from the
/// service; we project them into the canvas. Tapping a node sets the peek.
struct MindMapCanvas: View {
    let graph: MindMapGraph
    @Binding var peeked: MindMapNode?
    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Edges
                Canvas { ctx, size in
                    for edge in graph.edges {
                        guard
                            let a = graph.nodes.first(where: { $0.id == edge.source })?.position,
                            let b = graph.nodes.first(where: { $0.id == edge.target })?.position
                        else { continue }
                        var p = Path()
                        let pa = CGPoint(x: a.x * size.width, y: a.y * size.height)
                        let pb = CGPoint(x: b.x * size.width, y: b.y * size.height)
                        let mid = CGPoint(x: (pa.x + pb.x) / 2,
                                          y: (pa.y + pb.y) / 2 - 8)
                        p.move(to: pa)
                        p.addQuadCurve(to: pb, control: mid)
                        ctx.stroke(p,
                                   with: .color(theme.edge.opacity(max(0.3, edge.weight))),
                                   lineWidth: 1)
                    }
                }
                // Nodes
                ForEach(graph.nodes, id: \.id) { node in
                    nodeView(node)
                        .position(x: node.position.x * geo.size.width,
                                  y: node.position.y * geo.size.height)
                        .onTapGesture {
                            withAnimation(reduceMotion ? .none : .smooth) {
                                peeked = (peeked?.id == node.id) ? nil : node
                            }
                        }
                }
            }
        }
    }

    @ViewBuilder
    private func nodeView(_ node: MindMapNode) -> some View {
        let isCenter = node.importance > 4
        let pad: CGFloat = isCenter ? 18 : 10
        let fontSize: CGFloat = isCenter ? 14 : 11
        let height: CGFloat = isCenter ? 38 : 24
        Text(node.label)
            .font(.system(size: fontSize, weight: isCenter ? .bold : .medium))
            .foregroundStyle(theme.nodeText)
            .padding(.horizontal, pad)
            .frame(height: height)
            .background(Capsule().fill(theme.node))
            .overlay(
                Capsule().stroke(peeked?.id == node.id ? theme.accent : .clear,
                                 lineWidth: 2)
            )
            .accessibilityLabel(Text(node.label))
            .accessibilityAddTraits(.isButton)
    }
}
