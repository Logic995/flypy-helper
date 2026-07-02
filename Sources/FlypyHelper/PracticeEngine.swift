import SwiftUI

@MainActor
final class PracticeEngine: ObservableObject {
    @Published var mode: PracticeMode
    @Published var practice: PracticeUnit
    @Published var input = ""
    @Published var feedback = "直接输入双拼码"
    @Published var errorIndex: Int?
    @Published var errorKey: String?
    @Published var hintKey: String?
    @Published var currentMistakes = 0
    @Published var correctItems = 0
    @Published var attemptedItems = 0
    @Published var completedCharacters = 0
    @Published var typedKeys = 0
    @Published var bestKeysPerMinute = 0
    private let modeKey = "FlypyHelper.mode"
    private let bestKpmKey = "FlypyHelper.bestKeysPerMinute"
    private let profile: PracticeProfile

    private var startedAt = Date()
    private var lastWrongSignature = ""
    private var evaluationGeneration = 0
    private var pendingEvaluationTask: DispatchWorkItem?
    private var pendingResetTask: DispatchWorkItem?
    private var pendingHintTask: DispatchWorkItem?

    init(profile: PracticeProfile = PracticeProfile()) {
        self.profile = profile
        let savedMode = UserDefaults.standard.string(forKey: modeKey)
            .flatMap(PracticeMode.init(rawValue:)) ?? .character

        self.mode = savedMode
        self.bestKeysPerMinute = UserDefaults.standard.integer(forKey: bestKpmKey)
        self.practice = PracticeContent.pick(mode: savedMode, errorWeights: profile.errorWeights)
    }

    var targetCodes: [String] {
        practice.codes
    }

    var targetCodeString: String {
        targetCodes.joined()
    }

    var normalizedInput: String {
        InputEvaluator.normalize(input)
    }

    var inputProgressText: String {
        guard !normalizedInput.isEmpty else { return " " }
        return InputEvaluator.grouped(normalizedInput)
    }

    var expectedNextKey: String? {
        hintKey
    }

    private var nextKey: String? {
        let target = targetCodeString
        let index = normalizedInput.count
        guard errorKey == nil, index < target.count else { return nil }
        return String(Array(target)[index])
    }

    var currentCharacterIndex: Int {
        guard !targetCodes.isEmpty else { return 0 }
        return min(normalizedInput.count / 2, targetCodes.count - 1)
    }

    var shouldShowHint: Bool {
        currentMistakes >= 3
    }

    var currentHint: String {
        let index = errorIndex ?? currentCharacterIndex
        guard index < practice.pinyins.count, index < practice.codes.count else { return "" }
        let char = Array(practice.cleanText)[safe: index].map(String.init) ?? ""
        return "\(char)  \(practice.pinyins[index])  \(practice.codes[index])"
    }

    var accuracyText: String {
        guard attemptedItems > 0 else { return "准确率 0%" }
        let value = Int((Double(correctItems) / Double(attemptedItems) * 100).rounded())
        return "准确率 \(value)%"
    }

    var charactersPerMinute: Int {
        rate(for: completedCharacters)
    }

    var keysPerMinute: Int {
        rate(for: typedKeys)
    }

    var weakFinals: [(String, Int)] {
        profile.errorWeights
            .filter { $0.value > 0 }
            .sorted { lhs, rhs in
                if lhs.value == rhs.value {
                    return lhs.key < rhs.key
                }
                return lhs.value > rhs.value
            }
            .prefix(3)
            .map { ($0.key, $0.value) }
    }

    func switchMode(to newMode: PracticeMode) {
        mode = newMode
        UserDefaults.standard.set(newMode.rawValue, forKey: modeKey)
        nextPractice()
    }

    func handle(_ key: CapturedKey) {
        switch key {
        case .letter(let letter):
            append(letter)
        case .delete:
            deleteBackward()
        case .space:
            handleSpace()
        case .tab:
            showNextKeyHint()
        }
    }

    func nextPractice() {
        cancelPendingEvaluation()
        pendingResetTask?.cancel()
        pendingHintTask?.cancel()
        practice = PracticeContent.pick(mode: mode, errorWeights: profile.errorWeights)
        input = ""
        feedback = "直接输入双拼码"
        errorIndex = nil
        errorKey = nil
        hintKey = nil
        currentMistakes = 0
        lastWrongSignature = ""
    }

    func clearInput() {
        cancelPendingEvaluation()
        pendingResetTask?.cancel()
        pendingHintTask?.cancel()
        input = ""
        feedback = "已清空"
        errorIndex = nil
        errorKey = nil
        hintKey = nil
        lastWrongSignature = ""
    }

    private func handleSpace() {
        if normalizedInput.isEmpty || feedback == "正确" {
            nextPractice()
        } else if errorIndex == nil {
            input += " "
        }
    }

    private func append(_ letter: String) {
        guard errorIndex == nil else { return }

        hideNextKeyHint()
        input += letter.lowercased()
        typedKeys += 1

        if validationDelay > 0 {
            scheduleEvaluationAfterPause()
        } else {
            evaluateInput()
        }
    }

    private func deleteBackward() {
        cancelPendingEvaluation()
        pendingResetTask?.cancel()
        guard !input.isEmpty else { return }
        input.removeLast()
        feedback = progressFeedback
        errorIndex = nil
        errorKey = nil
        hintKey = nil
        lastWrongSignature = ""
    }

    private func evaluateInput() {
        pendingEvaluationTask = nil
        let result = InputEvaluator.evaluate(input: normalizedInput, targetCodes: targetCodes)

        switch result {
        case .empty:
            feedback = "直接输入双拼码"

        case .progress:
            feedback = progressFeedback

        case .wrong(let index, let expected, let actual):
            registerWrong(index: index, expected: expected, actual: actual)

        case .complete:
            registerCorrect()
        }
    }

    private func scheduleEvaluationAfterPause() {
        cancelPendingEvaluation()
        let generation = evaluationGeneration
        feedback = "\(progressFeedback) · 输入中"

        let task = DispatchWorkItem { [weak self] in
            Task { @MainActor in
                guard let self, self.evaluationGeneration == generation else { return }
                self.evaluateInput()
            }
        }
        pendingEvaluationTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + validationDelay, execute: task)
    }

    private func cancelPendingEvaluation() {
        evaluationGeneration += 1
        pendingEvaluationTask?.cancel()
        pendingEvaluationTask = nil
    }

    private var validationDelay: TimeInterval {
        switch mode {
        case .character, .phrase:
            0
        case .sentence:
            0.36
        case .article:
            0.46
        }
    }

    private func registerWrong(index: Int, expected: String, actual: String) {
        cancelPendingEvaluation()
        let signature = "\(practice.id.uuidString)|\(index)|\(actual)"
        guard signature != lastWrongSignature else { return }

        lastWrongSignature = signature
        attemptedItems += 1
        currentMistakes += 1
        errorIndex = index
        errorKey = mismatchedKey(expected: expected, actual: actual)
        hintKey = nil

        if index < practice.finals.count {
            increaseWeight(for: practice.finals[index])
        }

        if shouldShowHint {
            feedback = "看提示，再试"
        } else {
            feedback = "第 \(index + 1) 字不对  \(currentMistakes)/3"
        }

        scheduleRetryFrom(index: index)
    }

    private func registerCorrect() {
        cancelPendingEvaluation()
        pendingResetTask?.cancel()
        attemptedItems += 1
        correctItems += 1
        completedCharacters += practice.cleanText.count
        decayWeights(for: practice.finals)
        updateBest()
        feedback = "正确"

        let task = DispatchWorkItem { [weak self] in
            Task { @MainActor in
                self?.nextPractice()
            }
        }
        pendingResetTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32, execute: task)
    }

    private func scheduleRetryFrom(index: Int) {
        let prefixLength = max(0, index * 2)
        let preservedInput = String(normalizedInput.prefix(prefixLength))

        let task = DispatchWorkItem { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                if self.normalizedInput.hasPrefix(preservedInput) {
                    self.input = preservedInput
                    self.errorIndex = nil
                    self.errorKey = nil
                    self.hintKey = nil
                    self.feedback = self.shouldShowHint ? "看提示，再试" : self.progressFeedback
                }
            }
        }

        pendingResetTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.42, execute: task)
    }

    private func mismatchedKey(expected: String, actual: String) -> String {
        let expectedChars = Array(expected)
        let actualChars = Array(actual)
        let limit = min(expectedChars.count, actualChars.count)

        for offset in 0..<limit where expectedChars[offset] != actualChars[offset] {
            return String(actualChars[offset])
        }

        return actualChars.last.map(String.init) ?? expectedChars.first.map(String.init) ?? ""
    }

    private func showNextKeyHint() {
        pendingHintTask?.cancel()
        guard let nextKey else { return }

        hintKey = nextKey
        feedback = "提示：下一键 \(nextKey.uppercased())"

        let task = DispatchWorkItem { [weak self] in
            Task { @MainActor in
                self?.hideNextKeyHint()
            }
        }
        pendingHintTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: task)
    }

    private func hideNextKeyHint() {
        pendingHintTask?.cancel()
        hintKey = nil
    }

    private var progressFeedback: String {
        let completed = min(normalizedInput.count / 2, targetCodes.count)
        let half = normalizedInput.count % 2 == 1 ? " · 1/2" : ""
        return "\(completed)/\(targetCodes.count)\(half)"
    }

    private func rate(for count: Int) -> Int {
        let elapsedMinutes = max(Date().timeIntervalSince(startedAt) / 60, 0.1)
        return Int((Double(count) / elapsedMinutes).rounded())
    }

    private func updateBest() {
        let current = keysPerMinute
        guard current > bestKeysPerMinute else { return }
        bestKeysPerMinute = current
        UserDefaults.standard.set(current, forKey: bestKpmKey)
    }

    private func increaseWeight(for final: String) {
        profile.recordMistake(final: final)
    }

    private func decayWeights(for finals: [String]) {
        profile.recordSuccess(finals: finals)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
