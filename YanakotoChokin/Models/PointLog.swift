import Foundation
import SwiftData

@Model
final class PointLog {
    var id: UUID
    var yanakotoName: String
    var points: Int
    var timestamp: Date
    var isReward: Bool?

    init(id: UUID = UUID(), yanakotoName: String, points: Int, timestamp: Date = Date(), isReward: Bool = false) {
        self.id = id
        self.yanakotoName = yanakotoName
        self.points = points
        self.timestamp = timestamp
        self.isReward = isReward
    }
}
