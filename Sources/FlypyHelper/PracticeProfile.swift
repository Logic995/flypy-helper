import SwiftUI

@MainActor
final class PracticeProfile: ObservableObject {
    @Published private(set) var errorWeights: [String: Int]

    private let defaults: UserDefaults
    private let weightsKey = "FlypyHelper.errorWeights"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.errorWeights = defaults.dictionary(forKey: weightsKey) as? [String: Int] ?? [:]
    }

    func recordMistake(final: String) {
        errorWeights[final] = min((errorWeights[final] ?? 0) + 2, 18)
        save()
    }

    func recordSuccess(finals: [String]) {
        for final in Set(finals) {
            guard let current = errorWeights[final], current > 0 else { continue }
            errorWeights[final] = max(current - 1, 0)
        }
        save()
    }

    private func save() {
        defaults.set(errorWeights, forKey: weightsKey)
    }
}
