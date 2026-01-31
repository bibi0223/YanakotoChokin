import SwiftUI
import SwiftData

@main
struct YanakotoChokinApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Yanakoto.self,
            Reward.self,
            UserStats.self,
            PointLog.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        cleanupOldLogs()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }

    private func cleanupOldLogs() {
        let context = sharedModelContainer.mainContext
        let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()

        let descriptor = FetchDescriptor<PointLog>(
            predicate: #Predicate { $0.timestamp < oneMonthAgo }
        )

        do {
            let oldLogs = try context.fetch(descriptor)
            for log in oldLogs {
                context.delete(log)
            }
            if !oldLogs.isEmpty {
                try context.save()
            }
        } catch {
            print("Failed to cleanup old logs: \(error)")
        }
    }
}
