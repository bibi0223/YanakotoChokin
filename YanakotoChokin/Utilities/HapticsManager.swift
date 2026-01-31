import UIKit

final class HapticsManager {
    static let shared = HapticsManager()

    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let selectionGenerator = UISelectionFeedbackGenerator()

    private init() {
        prepareGenerators()
    }

    private func prepareGenerators() {
        lightGenerator.prepare()
        mediumGenerator.prepare()
        notificationGenerator.prepare()
        selectionGenerator.prepare()
    }

    func playSuccess() {
        notificationGenerator.notificationOccurred(.success)
        notificationGenerator.prepare()
    }

    func playLight() {
        lightGenerator.impactOccurred()
        lightGenerator.prepare()
    }

    func playMedium() {
        mediumGenerator.impactOccurred()
        mediumGenerator.prepare()
    }

    func playSelection() {
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare()
    }

    func playError() {
        notificationGenerator.notificationOccurred(.error)
        notificationGenerator.prepare()
    }

    func playWarning() {
        notificationGenerator.notificationOccurred(.warning)
        notificationGenerator.prepare()
    }
}
