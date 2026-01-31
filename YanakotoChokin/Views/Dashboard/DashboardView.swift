import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userStats: [UserStats]
    @Query(sort: \Yanakoto.createdAt) private var yanakotosQuery: [Yanakoto]

    private var yanakotos: [Yanakoto] {
        yanakotosQuery.sorted { a, b in
            let orderA = a.sortOrder ?? Int.max
            let orderB = b.sortOrder ?? Int.max
            if orderA != orderB {
                return orderA < orderB
            }
            return a.createdAt < b.createdAt
        }
    }

    @State private var undoAction: UndoAction?
    @State private var showUndoSnackbar = false
    @State private var showingAddSheet = false
    @State private var editingYanakoto: Yanakoto?
    @State private var undoWorkItem: DispatchWorkItem?

    private var stats: UserStats? {
        userStats.first
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    PointsStatusView(
                        currentPoints: stats?.currentPoints ?? 0,
                        totalPoints: stats?.totalPoints ?? 0
                    )
                    .padding(.top, 20)

                    if yanakotos.isEmpty {
                        EmptyYanakotoView()
                    } else {
                        YanakotoGridView(
                            yanakotos: yanakotos,
                            onTap: addPoints,
                            onEdit: { editingYanakoto = $0 },
                            onDelete: deleteYanakoto,
                            onMove: moveYanakoto
                        )
                    }

                    Spacer(minLength: 80)
                }
                .padding(.horizontal, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("やなこと貯金")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        HapticsManager.shared.playLight()
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                YanakotoEditSheet(yanakoto: nil) { name, points in
                    let maxOrder = yanakotos.compactMap(\.sortOrder).max() ?? -1
                    let newYanakoto = Yanakoto(name: name, points: points, sortOrder: maxOrder + 1)
                    modelContext.insert(newYanakoto)
                    HapticsManager.shared.playSuccess()
                }
            }
            .sheet(item: $editingYanakoto) { yanakoto in
                YanakotoEditSheet(yanakoto: yanakoto) { name, points in
                    yanakoto.name = name
                    yanakoto.points = points
                    HapticsManager.shared.playSuccess()
                }
            }
            .overlay(alignment: .bottom) {
                if showUndoSnackbar, let action = undoAction {
                    UndoSnackbar(
                        message: action.message,
                        onUndo: performUndo,
                        isDestructive: action.isDestructive
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 16)
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showUndoSnackbar)
        }
    }

    private func addPoints(yanakoto: Yanakoto) {
        guard let stats = stats else { return }
        // 負数・ゼロ・異常値のチェック
        guard yanakoto.points > 0, yanakoto.points <= 999999 else { return }

        HapticsManager.shared.playSuccess()

        stats.addPoints(yanakoto.points)

        let log = PointLog(yanakotoName: yanakoto.name, points: yanakoto.points)
        modelContext.insert(log)

        // 前のタイマーをキャンセル
        undoWorkItem?.cancel()

        let action = UndoAction.addPoints(points: yanakoto.points, logId: log.id)
        undoAction = action
        showUndoSnackbar = true

        scheduleUndoDismiss()
    }

    private func performUndo() {
        guard let action = undoAction else { return }

        // タイマーをキャンセル
        undoWorkItem?.cancel()
        undoWorkItem = nil

        HapticsManager.shared.playLight()

        switch action {
        case .addPoints(let points, let logId):
            guard let stats = stats else { return }
            stats.undoAddPoints(points)

            let targetLogId = logId
            let descriptor = FetchDescriptor<PointLog>(
                predicate: #Predicate { $0.id == targetLogId }
            )
            do {
                let logs = try modelContext.fetch(descriptor)
                if let log = logs.first {
                    modelContext.delete(log)
                }
            } catch {
                // フェッチ失敗時はログ削除をスキップ
            }

        case .deleteYanakoto(let name, let points, let sortOrder):
            // 削除したやなことを復元
            let restored = Yanakoto(name: name, points: points, sortOrder: sortOrder)
            modelContext.insert(restored)
        }

        withAnimation {
            showUndoSnackbar = false
        }
        undoAction = nil
    }

    private func deleteYanakoto(_ yanakoto: Yanakoto) {
        // 前のタイマーをキャンセル
        undoWorkItem?.cancel()

        // 削除前に情報を保存
        let action = UndoAction.deleteYanakoto(
            name: yanakoto.name,
            points: yanakoto.points,
            sortOrder: yanakoto.sortOrder
        )

        HapticsManager.shared.playLight()

        withAnimation(.easeOut(duration: 0.2)) {
            modelContext.delete(yanakoto)
        }

        undoAction = action
        showUndoSnackbar = true
        scheduleUndoDismiss()
    }

    private func scheduleUndoDismiss() {
        let workItem = DispatchWorkItem { [self] in
            withAnimation {
                showUndoSnackbar = false
            }
            undoAction = nil
        }
        undoWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 4, execute: workItem)
    }

    private func moveYanakoto(from source: Int, to destination: Int) {
        var items = yanakotos
        // 境界チェック
        guard source >= 0, source < items.count else { return }
        guard destination >= 0, destination < items.count else { return }

        let movedItem = items.remove(at: source)
        items.insert(movedItem, at: destination)

        for (index, item) in items.enumerated() {
            item.sortOrder = index
        }
        HapticsManager.shared.playLight()
    }
}

private enum UndoAction {
    case addPoints(points: Int, logId: UUID)
    case deleteYanakoto(name: String, points: Int, sortOrder: Int?)

    var message: String {
        switch self {
        case .addPoints(let points, _):
            return "+\(points)pt 追加"
        case .deleteYanakoto(let name, _, _):
            return "「\(name)」を削除"
        }
    }

    var isDestructive: Bool {
        switch self {
        case .addPoints:
            return false
        case .deleteYanakoto:
            return true
        }
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [Yanakoto.self, Reward.self, UserStats.self, PointLog.self], inMemory: true)
}
