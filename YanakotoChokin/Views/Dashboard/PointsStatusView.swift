import SwiftUI

struct PointsStatusView: View {
    let currentPoints: Int
    let totalPoints: Int

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("保有ポイント")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("\(currentPoints)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: currentPoints)

                Text("pt")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            Divider()
                .padding(.horizontal, 40)

            HStack(spacing: 8) {
                Text("累計")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("\(totalPoints)")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: totalPoints)

                Text("pt")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)
        )
    }
}

#Preview {
    PointsStatusView(currentPoints: 1250, totalPoints: 3400)
        .padding()
        .background(Color(.systemGroupedBackground))
}
