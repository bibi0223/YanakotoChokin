import SwiftUI

struct UndoSnackbar: View {
    let message: String
    let onUndo: () -> Void
    var isDestructive: Bool = false

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: isDestructive ? "trash.fill" : "checkmark.circle.fill")
                .foregroundStyle(isDestructive ? .red : .green)

            Text(message)
                .font(.subheadline)
                .fontWeight(.medium)

            Spacer()

            Button("取り消し") {
                onUndo()
            }
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(.blue)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        )
        .padding(.horizontal, 20)
    }
}

#Preview {
    UndoSnackbar(message: "+10pt 追加") {}
        .padding()
        .background(Color(.systemGroupedBackground))
}
