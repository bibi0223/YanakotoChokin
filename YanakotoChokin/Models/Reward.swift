import Foundation
import SwiftData

@Model
final class Reward {
    var id: UUID
    var name: String
    var requiredPoints: Int
    var createdAt: Date
    var sortOrder: Int?

    init(id: UUID = UUID(), name: String, requiredPoints: Int, createdAt: Date = Date(), sortOrder: Int? = nil) {
        self.id = id
        self.name = name
        self.requiredPoints = requiredPoints
        self.createdAt = createdAt
        self.sortOrder = sortOrder
    }
}
