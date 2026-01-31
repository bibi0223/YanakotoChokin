import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("ホーム", systemImage: "house.fill")
                }
                .tag(0)

            RewardsView()
                .tabItem {
                    Label("ご褒美", systemImage: "gift.fill")
                }
                .tag(1)

            SettingsView()
                .tabItem {
                    Label("履歴", systemImage: "clock.fill")
                }
                .tag(2)
        }
        .tint(.primary)
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [Yanakoto.self, Reward.self, UserStats.self, PointLog.self], inMemory: true)
}
