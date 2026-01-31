import SwiftUI
import SwiftData

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            HistoryView()
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Yanakoto.self, Reward.self, UserStats.self, PointLog.self], inMemory: true)
}
