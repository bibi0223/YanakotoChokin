import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.modelContext) private var modelContext
    @Query private var userStats: [UserStats]

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView(onComplete: {
                    initializeUserStats()
                    hasCompletedOnboarding = true
                })
            }
        }
    }

    private func initializeUserStats() {
        if userStats.isEmpty {
            let stats = UserStats(totalPoints: 0, currentPoints: 0)
            modelContext.insert(stats)
            // 明示的に保存してデータ永続化を確実に
            do {
                try modelContext.save()
            } catch {
                // 保存失敗時もアプリは継続（次回起動時に再試行）
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Yanakoto.self, Reward.self, UserStats.self, PointLog.self], inMemory: true)
}
