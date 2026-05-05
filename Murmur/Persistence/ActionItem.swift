import Foundation

struct ActionItem: Codable, Hashable, Identifiable {
    var id: UUID
    var text: String
    var assignedTo: String?
    var dueDate: Date?
    var isCompleted: Bool

    init(id: UUID = UUID(),
         text: String,
         assignedTo: String? = nil,
         dueDate: Date? = nil,
         isCompleted: Bool = false) {
        self.id = id
        self.text = text
        self.assignedTo = assignedTo
        self.dueDate = dueDate
        self.isCompleted = isCompleted
    }
}

enum ProcessingState: String, Codable, Hashable {
    case pending, recording, transcribing, summarizing, complete, failed
}

enum NodeType: String, Codable, Hashable {
    case call, topic
}

enum SentimentLabel: String, Codable, Hashable {
    case positive, neutral, negative, mixed
}
