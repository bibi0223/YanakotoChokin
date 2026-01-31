import SwiftUI
import SwiftData

struct YanakotoMasterView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Yanakoto.createdAt) private var yanakotos: [Yanakoto]

    @State private var showingAddSheet = false
    @State private var editingYanakoto: Yanakoto?

    var body: some View {
        List {
            ForEach(yanakotos, id: \.id) { yanakoto in
                Button {
                    editingYanakoto = yanakoto
                } label: {
                    HStack {
                        Text(yanakoto.name)
                            .foregroundStyle(.primary)

                        Spacer()

                        Text("\(yanakoto.points)pt")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onDelete(perform: deleteYanakotos)
        }
        .navigationTitle("やなことマスタ")
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
                let newYanakoto = Yanakoto(name: name, points: points)
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
    }

    private func deleteYanakotos(offsets: IndexSet) {
        HapticsManager.shared.playLight()
        // 逆順で削除してインデックスずれを防止
        for index in offsets.sorted().reversed() {
            guard index < yanakotos.count else { continue }
            modelContext.delete(yanakotos[index])
        }
    }
}

struct YanakotoEditSheet: View {
    @Environment(\.dismiss) private var dismiss

    let yanakoto: Yanakoto?
    let onSave: (String, Int) -> Void

    @State private var name: String = ""
    @State private var pointsText: String = "10"

    private var isEditing: Bool {
        yanakoto != nil
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && (Int(pointsText) ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Name input
                VStack(alignment: .leading, spacing: 8) {
                    Text("やなことの名前")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    TextField("例: 理不尽に怒られた", text: $name)
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
                    presets: [5, 10, 50, 100]
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
                        onSave(name, Int(pointsText) ?? 10)
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
                if let yanakoto = yanakoto {
                    name = yanakoto.name
                    pointsText = String(yanakoto.points)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    NavigationStack {
        YanakotoMasterView()
    }
    .modelContainer(for: [Yanakoto.self], inMemory: true)
}
