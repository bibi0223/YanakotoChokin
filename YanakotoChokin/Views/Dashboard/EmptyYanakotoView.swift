import SwiftUI

struct EmptyYanakotoView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)

            Text("やなことが登録されていません")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("右上の＋から追加できます")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

#Preview {
    EmptyYanakotoView()
        .background(Color(.systemGroupedBackground))
}
