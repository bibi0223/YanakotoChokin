import SwiftUI

struct PointInputView: View {
    @Binding var points: String
    let presets: [Int]
    var label: String = "ポイント"
    var description: String? = nil

    @State private var isCustomMode = false
    @FocusState private var isInputFocused: Bool

    private var currentValue: Int {
        Int(points) ?? 0
    }

    private var isPresetSelected: Bool {
        presets.contains(currentValue) && !isCustomMode
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Label and description
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(label)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if isCustomMode {
                        HStack(spacing: 4) {
                            TextField("0", text: $points)
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .focused($isInputFocused)
                                .frame(width: 80)
                                .onChange(of: points) { _, newValue in
                                    // 数字のみ、最大6桁まで
                                    let filtered = String(newValue.filter { $0.isNumber }.prefix(6))
                                    if filtered != newValue {
                                        points = filtered
                                    }
                                }
                            Text("pt")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("\(currentValue)pt")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .fixedSize()
                            .contentTransition(.numericText())
                    }
                }

                if let description = description {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            // Preset pills
            HStack(spacing: 8) {
                ForEach(presets, id: \.self) { preset in
                    PresetPill(
                        value: preset,
                        isSelected: currentValue == preset && !isCustomMode
                    ) {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                            points = String(preset)
                            isCustomMode = false
                            isInputFocused = false
                        }
                        HapticsManager.shared.playLight()
                    }
                }

                // Custom button
                PresetPill(
                    label: "他",
                    isSelected: isCustomMode || !isPresetSelected
                ) {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                        isCustomMode = true
                        isInputFocused = true
                    }
                    HapticsManager.shared.playLight()
                }
            }
        }
        .animation(.spring(response: 0.3), value: currentValue)
        .onChange(of: isInputFocused) { _, focused in
            if !focused && isCustomMode {
                if presets.contains(currentValue) {
                    isCustomMode = false
                }
            }
        }
    }
}

struct PresetPill: View {
    let value: Int?
    let label: String?
    let isSelected: Bool
    let action: () -> Void

    init(value: Int, isSelected: Bool, action: @escaping () -> Void) {
        self.value = value
        self.label = nil
        self.isSelected = isSelected
        self.action = action
    }

    init(label: String, isSelected: Bool, action: @escaping () -> Void) {
        self.value = nil
        self.label = label
        self.isSelected = isSelected
        self.action = action
    }

    private var displayText: String {
        if let value = value {
            return "\(value)"
        }
        return label ?? ""
    }

    var body: some View {
        Button(action: action) {
            Text(displayText)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(isSelected ? Color(.systemBackground) : .primary)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.primary : Color(.tertiarySystemBackground))
                )
                .overlay(
                    Capsule()
                        .stroke(Color.primary.opacity(isSelected ? 0 : 0.08), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
    }
}

#Preview {
    VStack(spacing: 40) {
        PreviewWrapper()
    }
    .padding(.vertical, 40)
}

private struct PreviewWrapper: View {
    @State private var points = "10"

    var body: some View {
        VStack(spacing: 32) {
            VStack(alignment: .leading, spacing: 8) {
                Text("やなことの名前")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                TextField("例: 電車遅延", text: .constant(""))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            PointInputView(
                points: $points,
                presets: [5, 10, 50, 100],
                description: "1回あたりに貯まるポイント"
            )
        }
        .padding(.horizontal, 20)
    }
}
