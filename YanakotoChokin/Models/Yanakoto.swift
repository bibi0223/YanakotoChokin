import Foundation
import SwiftData

@Model
final class Yanakoto {
    var id: UUID
    var name: String
    var points: Int
    var createdAt: Date
    var sortOrder: Int?

    init(id: UUID = UUID(), name: String, points: Int, createdAt: Date = Date(), sortOrder: Int? = nil) {
        self.id = id
        self.name = name
        self.points = points
        self.createdAt = createdAt
        self.sortOrder = sortOrder
    }
}
