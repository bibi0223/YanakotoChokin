import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    let onComplete: () -> Void

    @State private var currentPage = 0
    @State private var firstYanakotoName = ""
    @State private var firstYanakotoPoints = "10"

    private let totalPages = 2

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                PhilosophyPage()
                    .tag(0)

                FirstYanakotoPage(
                    name: $firstYanakotoName,
                    points: $firstYanakotoPoints,
                    onComplete: completeOnboarding
                )
                .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: currentPage)

            PageIndicator(currentPage: currentPage, totalPages: totalPages)
                .padding(.bottom, 20)

            Button {
                HapticsManager.shared.playLight()
                withAnimation {
                    currentPage += 1
                }
            } label: {
                Text("次へ")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.primary)
                    .foregroundStyle(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
            .opacity(currentPage < totalPages - 1 ? 1 : 0)
            .allowsHitTesting(currentPage < totalPages - 1)
        }
        .background(Color(.systemBackground))
        .ignoresSafeArea(.keyboard)
    }

    private func completeOnboarding() {
        if !firstYanakotoName.trimmingCharacters(in: .whitespaces).isEmpty {
            let points = Int(firstYanakotoPoints) ?? 10
            let yanakoto = Yanakoto(name: firstYanakotoName, points: points, sortOrder: 0)
            modelContext.insert(yanakoto)
        }

        HapticsManager.shared.playSuccess()
        onComplete()
    }
}

private struct PhilosophyPage: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 32) {
                Text("☕️")
                    .font(.system(size: 72))

                VStack(spacing: 16) {
                    Text("いつもおつかれさまです")
                        .font(.system(size: 28, weight: .bold))

                    Text("日々のやなことを貯金して\nご褒美に変えましょう")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

private struct FirstYanakotoPage: View {
    @Binding var name: String
    @Binding var points: String
    let onComplete: () -> Void

    @FocusState private var focusedField: Field?

    private enum Field {
        case name
    }

    private var canComplete: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func dismissKeyboard() {
        focusedField = nil
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    Spacer(minLength: 60)

                    VStack(spacing: 12) {
                        Text("最初の「やなこと」を\n登録しましょう")
                            .font(.system(size: 24, weight: .bold))
                            .multilineTextAlignment(.center)

                        Text("あとから変更・追加できます")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: 28) {
                        // Name input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("やなことの名前")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            TextField("例: 理不尽に怒られた", text: $name)
                                .font(.body)
                                .padding(16)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color(.separator), lineWidth: 0.5)
                                )
                                .focused($focusedField, equals: .name)
                        }

                        // Point selector
                        PointInputView(
                            points: $points,
                            presets: [5, 10, 50, 100]
                        )
                    }
                    .padding(.top, 24)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
            }
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture {
                dismissKeyboard()
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完了") {
                        dismissKeyboard()
                    }
                }
            }

            Button {
                dismissKeyboard()
                onComplete()
            } label: {
                Text("はじめる")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(canComplete ? Color.primary : Color.secondary.opacity(0.3))
                    .foregroundStyle(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .disabled(!canComplete)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

private struct PageIndicator: View {
    let currentPage: Int
    let totalPages: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? Color.primary : Color.secondary.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut(duration: 0.2), value: currentPage)
            }
        }
    }
}

#Preview {
    OnboardingView(onComplete: {})
        .modelContainer(for: [Yanakoto.self, Reward.self, UserStats.self], inMemory: true)
}
