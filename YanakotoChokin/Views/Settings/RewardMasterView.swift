import SwiftUI
import SwiftData

struct RewardMasterView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Reward.requiredPoints) private var rewards: [Reward]

    @State private var showingAddSheet = false
    @State private var editingReward: Reward?

    var body: some View {
        List {
            ForEach(rewards, id: \.id) { reward in
                Button {
                    editingReward = reward
                } label: {
                    HStack {
                        Text(reward.name)
                            .foregroundStyle(.primary)

                        Spacer()

                        Text("\(reward.requiredPoints)pt")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onDelete(perform: deleteRewards)
        }
        .navigationTitle("ご褒美マスタ")
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
                let newReward = Reward(name: name, requiredPoints: points)
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
    }

    private func deleteRewards(offsets: IndexSet) {
        HapticsManager.shared.playLight()
        // 逆順で削除してインデックスずれを防止
        for index in offsets.sorted().reversed() {
            guard index < rewards.count else { continue }
            modelContext.delete(rewards[index])
        }
    }
}

struct RewardEditSheet: View {
    @Environment(\.dismiss) private var dismiss

    let reward: Reward?
    let onSave: (String, Int) -> Void

    @State private var name: String = ""
    @State private var pointsText: String = "100"

    private var isEditing: Bool {
        reward != nil
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && (Int(pointsText) ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Name input
                VStack(alignment: .leading, spacing: 8) {
                    Text("ご褒美の名前")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    TextField("例: おいしいコーヒー", text: $name)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color(.separator), lineWidth: 0.5)
                        )
                }

                // Point input
                PointInputView(
                    points: $pointsText,
                    presets: [50, 100, 500, 1000],
                    label: "必要ポイント"
                )

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .background(Color(.systemGroupedBackground))
            .navigationTitle(isEditing ? "編集" : "新規追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        onSave(name, Int(pointsText) ?? 100)
                        dismiss()
                    }
                    .disabled(!canSave)
                }

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完了") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
            }
            .onAppear {
                if let reward = reward {
                    name = reward.name
                    pointsText = String(reward.requiredPoints)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    NavigationStack {
        RewardMasterView()
    }
    .modelContainer(for: [Reward.self], inMemory: true)
}
