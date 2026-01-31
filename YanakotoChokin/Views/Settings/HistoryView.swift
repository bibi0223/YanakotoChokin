import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PointLog.timestamp, order: .reverse) private var logs: [PointLog]
    @Query private var userStats: [UserStats]

    private var stats: UserStats? {
        userStats.first
    }

    private var groupedLogs: [(String, [PointLog])] {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "ja_JP")

        // O(n) でグループ化
        let grouped = Dictionary(grouping: logs) { log in
            formatter.string(from: log.timestamp)
        }

        // O(n log n) でソート - 各グループの最初のログのタイムスタンプを使用
        return grouped.sorted { pair1, pair2 in
            let date1 = pair1.value.first?.timestamp ?? Date.distantPast
            let date2 = pair2.value.first?.timestamp ?? Date.distantPast
            return date1 > date2
        }
    }

    var body: some View {
        List {
            if logs.isEmpty {
                ContentUnavailableView(
                    "履歴がありません",
                    systemImage: "clock",
                    description: Text("ポイントの獲得・交換履歴が表示されます")
                )
            } else {
                ForEach(groupedLogs, id: \.0) { dateString, logsForDate in
                    Section(dateString) {
                        ForEach(logsForDate, id: \.id) { log in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 6) {
                                        Image(systemName: log.isReward == true ? "gift.fill" : "plus.circle.fill")
                                            .font(.caption)
                                            .foregroundStyle(log.isReward == true ? .orange : .blue)

                                        Text(log.yanakotoName)
                                            .font(.body)
                                    }

                                    Text(log.timestamp, style: .time)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Text(log.points >= 0 ? "+\(log.points)pt" : "\(log.points)pt")
                                    .font(.system(.body, design: .rounded))
                                    .fontWeight(.medium)
                                    .foregroundStyle(log.isReward == true ? .orange : .blue)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    undoLog(log)
                                } label: {
                                    Image(systemName: "arrow.uturn.backward")
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("履歴")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func undoLog(_ log: PointLog) {
        guard let stats = stats else { return }

        // Revert the points
        if log.isReward == true {
            // Reward was exchanged (negative points), so add back
            // log.points is negative, so subtracting it adds to currentPoints
            let newPoints = stats.currentPoints - log.points
            stats.currentPoints = min(newPoints, Int.max - 1) // オーバーフロー防止
        } else {
            // Points were added, so subtract
            stats.currentPoints -= log.points
            stats.totalPoints -= log.points
        }

        // Ensure points don't go negative
        stats.currentPoints = max(0, stats.currentPoints)
        stats.totalPoints = max(0, stats.totalPoints)

        modelContext.delete(log)
        HapticsManager.shared.playLight()
    }
}

#Preview {
    NavigationStack {
        HistoryView()
    }
    .modelContainer(for: [PointLog.self, UserStats.self], inMemory: true)
}
