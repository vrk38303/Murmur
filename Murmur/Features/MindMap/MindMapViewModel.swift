import Foundation
import SwiftUI

enum MindMapFilter: String, CaseIterable {
    case all, people, topics
    var label: LocalizedStringKey {
        switch self {
        case .all:    return "map.filter.all"
        case .people: return "map.filter.people"
        case .topics: return "map.filter.topics"
        }
    }
}

@MainActor
@Observable
final class MindMapViewModel {
    var filter: MindMapFilter = .all
    var graph: MindMapGraph = .empty
    var peeked: MindMapNode?
    var query: String = ""
    var error: AppError?

    private let services: ServiceContainer

    init(services: ServiceContainer) {
        self.services = services
    }

    func load() async {
        do {
            let g = try await services.mindMap.graph()
            self.graph = filtered(graph: g)
        } catch {
            self.error = .persistenceFailed(error.localizedDescription)
        }
    }

    private func filtered(graph: MindMapGraph) -> MindMapGraph {
        let nodes: [MindMapNode]
        switch filter {
        case .all:
            nodes = graph.nodes
        case .people:
            nodes = graph.nodes.filter { $0.type == .call }
        case .topics:
            nodes = graph.nodes.filter { $0.type == .topic }
        }
        let allowed = Set(nodes.map(\.id))
        let edges = graph.edges.filter {
            allowed.contains($0.source) && allowed.contains($0.target)
        }
        return MindMapGraph(nodes: nodes, edges: edges)
    }
}
