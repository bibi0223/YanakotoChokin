import SwiftUI

struct YanakotoGridView: View {
    let yanakotos: [Yanakoto]
    let onTap: (Yanakoto) -> Void
    let onEdit: (Yanakoto) -> Void
    let onDelete: (Yanakoto) -> Void
    let onMove: (Int, Int) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("やなことリスト")
                .font(.headline)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(Array(yanakotos.enumerated()), id: \.element.id) { index, yanakoto in
                    YanakotoCardButton(
                        yanakoto: yanakoto,
                        index: index,
                        total: yanakotos.count,
                        onTap: onTap,
                        onEdit: onEdit,
                        onDelete: onDelete,
                        onMoveUp: index > 0 ? { onMove(index, index - 1) } : nil,
                        onMoveDown: index < yanakotos.count - 1 ? { onMove(index, index + 1) } : nil
                    )
                }
            }
        }
    }
}

struct YanakotoCardButton: View {
    let yanakoto: Yanakoto
    let index: Int
    let total: Int
    let onTap: (Yanakoto) -> Void
    let onEdit: (Yanakoto) -> Void
    let onDelete: (Yanakoto) -> Void
    let onMoveUp: (() -> Void)?
    let onMoveDown: (() -> Void)?

    @State private var isDebouncing = false
    @State private var showAddedFeedback = false

    var body: some View {
        VStack(spacing: 12) {
            Text(yanakoto.name)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            Text("+\(yanakoto.points)pt")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.blue)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
        .overlay {
            if showAddedFeedback {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.blue.opacity(0.5), lineWidth: 2)
                    .scaleEffect(1.05)
                    .opacity(showAddedFeedback ? 0 : 1)
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .opacity(isDebouncing ? 0.7 : 1.0)
        .onTapGesture {
            guard !isDebouncing else { return }
            HapticsManager.shared.playLight()
            handleTap()
        }
        .contextMenu {
            Button {
                onEdit(yanakoto)
            } label: {
                Label("編集", systemImage: "pencil")
            }

            if let onMoveUp = onMoveUp {
                Button {
                    onMoveUp()
                } label: {
                    Label("前に移動", systemImage: "arrow.up")
                }
            }

            if let onMoveDown = onMoveDown {
                Button {
                    onMoveDown()
                } label: {
                    Label("後ろに移動", systemImage: "arrow.down")
                }
            }

            Divider()

            Button(role: .destructive) {
                onDelete(yanakoto)
            } label: {
                Label("削除", systemImage: "trash")
            }
        }
    }

    private func handleTap() {
        guard !isDebouncing else { return }

        isDebouncing = true

        withAnimation(.easeOut(duration: 0.3)) {
            showAddedFeedback = true
        }

        onTap(yanakoto)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showAddedFeedback = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            isDebouncing = false
        }
    }
}

#Preview {
    let sampleYanakotos = [
        Yanakoto(name: "電車遅延", points: 10),
        Yanakoto(name: "理不尽なクレーム", points: 50),
        Yanakoto(name: "急な予定変更", points: 20),
        Yanakoto(name: "天気の急変", points: 5)
    ]

    YanakotoGridView(
        yanakotos: sampleYanakotos,
        onTap: { _ in },
        onEdit: { _ in },
        onDelete: { _ in },
        onMove: { _, _ in }
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Card") {
    YanakotoCardButton(
        yanakoto: Yanakoto(name: "電車遅延", points: 10),
        index: 0,
        total: 4,
        onTap: { _ in },
        onEdit: { _ in },
        onDelete: { _ in },
        onMoveUp: nil,
        onMoveDown: {}
    )
    .padding()
}
