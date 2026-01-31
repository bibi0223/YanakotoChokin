import Foundation
import SwiftData

@Model
final class UserStats {
    var totalPoints: Int
    var currentPoints: Int

    init(totalPoints: Int = 0, currentPoints: Int = 0) {
        self.totalPoints = totalPoints
        self.currentPoints = currentPoints
    }

    private let maxSafePoints = Int.max - 1_000_000 // オーバーフロー防止のマージン

    func addPoints(_ points: Int) {
        // 負数・ゼロは無視
        guard points > 0 else { return }
        // オーバーフロー防止
        if totalPoints <= maxSafePoints {
            totalPoints += points
        }
        if currentPoints <= maxSafePoints {
            currentPoints += points
        }
    }

    func subtractPoints(_ points: Int) {
        guard points > 0 else { return }
        currentPoints = max(0, currentPoints - points)
    }

    func undoAddPoints(_ points: Int) {
        guard points > 0 else { return }
        totalPoints = max(0, totalPoints - points)
        currentPoints = max(0, currentPoints - points)
    }
}
