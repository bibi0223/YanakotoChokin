import SwiftUI
import SwiftData

struct RewardsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Reward.createdAt) private var rewardsQuery: [Reward]
    @Query private var userStats: [UserStats]

    private var rewards: [Reward] {
        rewardsQuery.sorted { a, b in
            let orderA = a.sortOrder ?? Int.max
            let orderB = b.sortOrder ?? Int.max
            if orderA != orderB {
                return orderA < orderB
            }
            return a.createdAt < b.createdAt
        }
    }

    @State private var showingExchangeConfirmation = false
    @State private var rewardToExchange: Reward?
    @State private var showingAddSheet = false
    @State private var editingReward: Reward?
    @State private var showingCelebration = false
    @State private var celebratedRewardName = ""
    @State private var deletedReward: DeletedReward?
    @State private var showDeleteUndo = false
    @State private var deleteUndoWorkItem: DispatchWorkItem?

    private var stats: UserStats? {
        userStats.first
    }

    private var currentPoints: Int {
        stats?.currentPoints ?? 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if rewards.isEmpty {
                    VStack(spacing: 16) {
                        Spacer(minLength: 100)

                        Image(systemName: "gift")
                            .font(.system(size: 48))
                            .foregroundStyle(.tertiary)

                        Text("ご褒美が登録されていません")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text("右上の＋から追加できます")
                            .font(.caption)
                            .foregroundStyle(.tertiary)

                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(Array(rewards.enumerated()), id: \.element.id) { index, reward in
                            RewardCard(
                                reward: reward,
                                currentPoints: currentPoints,
                                onExchange: {
                                    rewardToExchange = reward
                                    showingExchangeConfirmation = true
                                },
                                onEdit: { editingReward = reward },
                                onDelete: { deleteReward(reward) },
                                onMoveUp: index > 0 ? { moveReward(from: index, to: index - 1) } : nil,
                                onMoveDown: index < rewards.count - 1 ? { moveReward(from: index, to: index + 1) } : nil
                            )
                        }
                    }
                    .padding(20)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("ご褒美")
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
                RewardEditSheet(reward: nil) { name, points in
                    let maxOrder = rewards.compactMap(\.sortOrder).max() ?? -1
                    let newReward = Reward(name: name, requiredPoints: points, sortOrder: maxOrder + 1)
                    modelContext.insert(newReward)
                    HapticsManager.shared.playSuccess()
                }
            }
            .sheet(item: $editingReward) { reward in
                RewardEditSheet(reward: reward) { name, points in
                    reward.name = name
                    reward.requiredPoints = points
                    HapticsManager.shared.playSuccess()
                }
            }
            .overlay {
                if showingExchangeConfirmation, let reward = rewardToExchange {
                    ExchangeConfirmationOverlay(
                        reward: reward,
                        onConfirm: {
                            showingExchangeConfirmation = false
                            exchangeReward(reward)
                        },
                        onCancel: {
                            showingExchangeConfirmation = false
                        }
                    )
                    .transition(.opacity)
                }
            }
            .overlay {
                if showingCelebration {
                    CelebrationOverlay(rewardName: celebratedRewardName) {
                        withAnimation {
                            showingCelebration = false
                        }
                    }
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: showingExchangeConfirmation)
            .overlay(alignment: .bottom) {
                if showDeleteUndo, let deleted = deletedReward {
                    UndoSnackbar(
                        message: "「\(deleted.name)」を削除",
                        onUndo: undoDeleteReward,
                        isDestructive: true
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 16)
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showDeleteUndo)
        }
    }

    private func exchangeReward(_ reward: Reward) {
        guard let stats = stats, stats.currentPoints >= reward.requiredPoints else { return }
        // 負数・ゼロ・異常値のチェック
        guard reward.requiredPoints > 0, reward.requiredPoints <= 999999 else { return }

        stats.subtractPoints(reward.requiredPoints)

        let log = PointLog(
            yanakotoName: reward.name,
            points: -reward.requiredPoints,
            isReward: true
        )
        modelContext.insert(log)

        celebratedRewardName = reward.name
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            showingCelebration = true
        }
        HapticsManager.shared.playSuccess()
    }

    private func deleteReward(_ reward: Reward) {
        // 前のタイマーをキャンセル
        deleteUndoWorkItem?.cancel()

        // 削除前に情報を保存
        deletedReward = DeletedReward(
            name: reward.name,
            requiredPoints: reward.requiredPoints,
            sortOrder: reward.sortOrder
        )

        HapticsManager.shared.playLight()

        withAnimation(.easeOut(duration: 0.2)) {
            modelContext.delete(reward)
        }

        showDeleteUndo = true
        scheduleDeleteUndoDismiss()
    }

    private func undoDeleteReward() {
        guard let deleted = deletedReward else { return }

        deleteUndoWorkItem?.cancel()
        deleteUndoWorkItem = nil

        HapticsManager.shared.playLight()

        let restored = Reward(
            name: deleted.name,
            requiredPoints: deleted.requiredPoints,
            sortOrder: deleted.sortOrder
        )
        modelContext.insert(restored)

        withAnimation {
            showDeleteUndo = false
        }
        deletedReward = nil
    }

    private func scheduleDeleteUndoDismiss() {
        let workItem = DispatchWorkItem { [self] in
            withAnimation {
                showDeleteUndo = false
            }
            deletedReward = nil
        }
        deleteUndoWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 4, execute: workItem)
    }

    private func moveReward(from source: Int, to destination: Int) {
        var items = rewards
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

struct RewardCard: View {
    let reward: Reward
    let currentPoints: Int
    let onExchange: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onMoveUp: (() -> Void)?
    let onMoveDown: (() -> Void)?

    private var progress: Double {
        min(Double(currentPoints) / Double(reward.requiredPoints), 1.0)
    }

    private var canExchange: Bool {
        currentPoints >= reward.requiredPoints
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(reward.name)
                    .font(.headline)

                Spacer()

                Text("\(reward.requiredPoints)pt")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(canExchange ? Color.green : Color.blue)
                            .frame(width: geometry.size.width * progress, height: 8)
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: progress)
                    }
                }
                .frame(height: 8)

                HStack {
                    Text("\(currentPoints) / \(reward.requiredPoints) pt")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(canExchange ? .green : .secondary)
                }
            }

            Button {
                HapticsManager.shared.playLight()
                onExchange()
            } label: {
                Text("交換する")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(canExchange ? Color.primary : Color(.systemGray4))
                    .foregroundStyle(canExchange ? Color(.systemBackground) : Color(.systemGray))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .disabled(!canExchange)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
        .contextMenu {
            Button {
                onEdit()
            } label: {
                Label("編集", systemImage: "pencil")
            }

            if let onMoveUp = onMoveUp {
                Button {
                    onMoveUp()
                } label: {
                    Label("上に移動", systemImage: "arrow.up")
                }
            }

            if let onMoveDown = onMoveDown {
                Button {
                    onMoveDown()
                } label: {
                    Label("下に移動", systemImage: "arrow.down")
                }
            }

            Divider()

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("削除", systemImage: "trash")
            }
        }
    }
}

struct ExchangeConfirmationOverlay: View {
    let reward: Reward
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    onCancel()
                }

            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Text("ご褒美と交換")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text("「\(reward.name)」\nと交換しますか？")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 12) {
                    Button {
                        HapticsManager.shared.playLight()
                        onConfirm()
                    } label: {
                        Text("交換する（−\(reward.requiredPoints)pt）")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.primary)
                            .foregroundStyle(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    Button {
                        onCancel()
                    } label: {
                        Text("キャンセル")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                    }
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(.systemBackground))
            )
            .padding(.horizontal, 40)
        }
    }
}

struct CelebrationOverlay: View {
    let rewardName: String
    let onDismiss: () -> Void

    @State private var showContent = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Image(systemName: "gift.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(.white)
                    .scaleEffect(showContent ? 1 : 0.5)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showContent)

                VStack(spacing: 16) {
                    Text("おつかれさま！")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)

                    Text("「\(rewardName)」")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.white)

                    Text("をゲットしました")
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .multilineTextAlignment(.center)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 15)
                .animation(.easeOut(duration: 0.4).delay(0.15), value: showContent)

                Text("タップして閉じる")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.top, 24)
                    .opacity(showContent ? 1 : 0)
                    .animation(.easeOut(duration: 0.3).delay(0.5), value: showContent)
            }
            .padding(40)
        }
        .onAppear {
            showContent = true
        }
        .onTapGesture {
            onDismiss()
        }
    }
}

private struct DeletedReward {
    let name: String
    let requiredPoints: Int
    let sortOrder: Int?
}

#Preview {
    RewardsView()
        .modelContainer(for: [Yanakoto.self, Reward.self, UserStats.self, PointLog.self], inMemory: true)
}

#Preview("Celebration") {
    CelebrationOverlay(rewardName: "おいしいコーヒー") {}
}
