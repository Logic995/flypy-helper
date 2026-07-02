import SwiftUI

enum ChallengePhase: Equatable {
    case ready
    case running
    case finished
}

@MainActor
final class ChallengeEngine: ObservableObject {
    typealias PromptProvider = (_ errorWeights: [String: Int], _ excludedTexts: Set<String>) -> PracticeUnit

    @Published private(set) var phase: ChallengePhase = .ready
    @Published private(set) var practice: PracticeUnit
    @Published private(set) var input = ""
    @Published private(set) var feedback = "按 SPACE 开始"
    @Published private(set) var errorKey: String?
    @Published private(set) var hintKey: String?
    @Published private(set) var timeRemaining: TimeInterval
    @Published private(set) var score = 0
    @Published private(set) var combo = 0
    @Published private(set) var maxCombo = 0
    @Published private(set) var correctCharacters = 0
    @Published private(set) var typedKeys = 0
    @Published private(set) var wrongCodes = 0
    @Published private(set) var skippedPrompts = 0
    @Published private(set) var hintsUsed = 0
    @Published private(set) var latestResult: ChallengeResult?

    let history: ChallengeHistoryStore

    private let profile: PracticeProfile
    private let duration: TimeInterval
    private let now: () -> Date
    private let promptProvider: PromptProvider
    private let automaticallyTicks: Bool
    private var startedAt: Date?
    private var endsAt: Date?
    private var validatedCodes = 0
    private var recentTexts: [String] = []
    private var tickGeneration = 0
    private var pendingTick: DispatchWorkItem?
    private var hintGeneration = 0
    private var errorGeneration = 0

    init(
        profile: PracticeProfile,
        history: ChallengeHistoryStore = ChallengeHistoryStore(),
        duration: TimeInterval = 60,
        automaticallyTicks: Bool = true,
        now: @escaping () -> Date = Date.init,
        promptProvider: PromptProvider? = nil
    ) {
        self.profile = profile
        self.history = history
        self.duration = duration
        self.timeRemaining = duration
        self.automaticallyTicks = automaticallyTicks
        self.now = now
        self.promptProvider = promptProvider ?? { weights, excluded in
            PracticeContent.pick(mode: .phrase, errorWeights: weights, excludingTexts: excluded)
        }
        self.practice = PracticeContent.pick(mode: .phrase, errorWeights: profile.errorWeights)
    }

    var inputProgressText: String {
        let grouped = InputEvaluator.grouped(input)
        return grouped.isEmpty ? " " : grouped
    }

    var expectedNextKey: String? { hintKey }

    var currentHint: String {
        let index = min(InputEvaluator.normalize(input).count / 2, max(0, practice.pinyins.count - 1))
        guard index < practice.pinyins.count, index < practice.codes.count else { return "" }
        let character = Array(practice.cleanText)[safe: index].map(String.init) ?? ""
        return "\(character)  \(practice.pinyins[index])  \(practice.codes[index])"
    }

    var accuracy: Double {
        let attempts = correctCharacters + wrongCodes
        guard attempts > 0 else { return 0 }
        return Double(correctCharacters) / Double(attempts)
    }

    var accuracyText: String {
        "准确率 \(Int((accuracy * 100).rounded()))%"
    }

    var charactersPerMinute: Int {
        liveRate(for: correctCharacters)
    }

    var keysPerMinute: Int {
        liveRate(for: typedKeys)
    }

    var progress: Double {
        guard duration > 0 else { return 0 }
        return max(0, min(1, timeRemaining / duration))
    }

    func prepare() {
        cancelTicking()
        phase = .ready
        timeRemaining = duration
        feedback = "按 SPACE 开始"
        latestResult = nil
        resetRoundValues()
        selectNextPrompt()
    }

    func start() {
        guard phase != .running else { return }
        cancelTicking()
        resetRoundValues()
        latestResult = nil
        phase = .running
        feedback = "开始"
        let start = now()
        startedAt = start
        endsAt = start.addingTimeInterval(duration)
        timeRemaining = duration
        selectNextPrompt()
        if automaticallyTicks {
            scheduleTick()
        }
    }

    func cancel() {
        cancelTicking()
        resetRoundValues()
        phase = .ready
        timeRemaining = duration
        feedback = "按 SPACE 开始"
        latestResult = nil
    }

    func handle(_ key: CapturedKey) {
        switch phase {
        case .ready, .finished:
            if case .space = key { start() }
        case .running:
            tick(at: now())
            guard phase == .running else { return }
            switch key {
            case .letter(let letter): append(letter)
            case .delete: deleteBackward()
            case .space: skipPrompt()
            case .tab: showNextKeyHint()
            }
        }
    }

    func tick(at date: Date) {
        guard phase == .running, let endsAt else { return }
        let remaining = endsAt.timeIntervalSince(date)
        if remaining <= 0 {
            finish(at: date)
        } else {
            timeRemaining = remaining
        }
    }

    private func append(_ letter: String) {
        hideHint()
        input += letter.lowercased()
        typedKeys += 1
        evaluateInput()
    }

    private func deleteBackward() {
        guard !input.isEmpty else { return }
        input.removeLast()
        validatedCodes = min(validatedCodes, InputEvaluator.normalize(input).count / 2)
        feedback = progressFeedback
    }

    private func evaluateInput() {
        let normalized = InputEvaluator.normalize(input)
        let result = InputEvaluator.evaluate(input: normalized, targetCodes: practice.codes)

        switch result {
        case .empty:
            feedback = "直接输入双拼码"
        case .progress:
            registerNewCorrectCodes(upTo: normalized.count / 2)
            feedback = progressFeedback
        case .complete:
            registerNewCorrectCodes(upTo: practice.codes.count)
            profile.recordSuccess(finals: practice.finals)
            feedback = "正确"
            selectNextPrompt()
        case .wrong(let index, let expected, let actual):
            registerWrong(index: index, expected: expected, actual: actual)
        }
    }

    private func registerNewCorrectCodes(upTo count: Int) {
        guard count > validatedCodes else { return }
        for _ in validatedCodes..<count {
            correctCharacters += 1
            combo += 1
            maxCombo = max(maxCombo, combo)
            score += pointsForCurrentCombo
        }
        validatedCodes = count
    }

    private var pointsForCurrentCombo: Int {
        switch combo {
        case 40...: 200
        case 20..<40: 150
        case 10..<20: 125
        default: 100
        }
    }

    private func registerWrong(index: Int, expected: String, actual: String) {
        wrongCodes += 1
        combo = 0
        if index < practice.finals.count {
            profile.recordMistake(final: practice.finals[index])
        }

        errorGeneration += 1
        let generation = errorGeneration
        errorKey = mismatchedKey(expected: expected, actual: actual)
        input = String(InputEvaluator.normalize(input).prefix(max(0, index * 2)))
        validatedCodes = min(validatedCodes, index)
        feedback = "第 \(index + 1) 字不对，重试"

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { [weak self] in
            guard let self, self.errorGeneration == generation else { return }
            self.errorKey = nil
        }
    }

    private func skipPrompt() {
        skippedPrompts += 1
        combo = 0
        feedback = "已跳过"
        selectNextPrompt()
    }

    private func showNextKeyHint() {
        let target = practice.codes.joined()
        let index = InputEvaluator.normalize(input).count
        guard index < target.count else { return }

        combo = 0
        hintsUsed += 1
        hintGeneration += 1
        let generation = hintGeneration
        hintKey = String(Array(target)[index])
        feedback = "提示：下一键 \(hintKey?.uppercased() ?? "")"

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            guard let self, self.hintGeneration == generation else { return }
            self.hintKey = nil
        }
    }

    private func hideHint() {
        hintGeneration += 1
        hintKey = nil
    }

    private func selectNextPrompt() {
        let excluded = Set(recentTexts.suffix(3))
        practice = promptProvider(profile.errorWeights, excluded)
        recentTexts.append(practice.text)
        if recentTexts.count > 3 {
            recentTexts.removeFirst(recentTexts.count - 3)
        }
        input = ""
        validatedCodes = 0
        errorKey = nil
        hintKey = nil
    }

    private func finish(at date: Date) {
        guard phase == .running else { return }
        cancelTicking()
        phase = .finished
        timeRemaining = 0

        let result = ChallengeResult(
            completedAt: date,
            duration: duration,
            correctCharacters: correctCharacters,
            typedKeys: typedKeys,
            wrongCodes: wrongCodes,
            skippedPrompts: skippedPrompts,
            hintsUsed: hintsUsed,
            score: score,
            maxCombo: maxCombo
        )
        latestResult = result
        history.record(result)
        feedback = "挑战完成"
    }

    private func scheduleTick() {
        tickGeneration += 1
        let generation = tickGeneration
        let task = DispatchWorkItem { [weak self] in
            Task { @MainActor in
                guard let self, self.tickGeneration == generation, self.phase == .running else { return }
                self.tick(at: self.now())
                if self.phase == .running {
                    self.scheduleTick()
                }
            }
        }
        pendingTick = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: task)
    }

    private func cancelTicking() {
        tickGeneration += 1
        pendingTick?.cancel()
        pendingTick = nil
    }

    private func resetRoundValues() {
        input = ""
        score = 0
        combo = 0
        maxCombo = 0
        correctCharacters = 0
        typedKeys = 0
        wrongCodes = 0
        skippedPrompts = 0
        hintsUsed = 0
        validatedCodes = 0
        recentTexts = []
        errorKey = nil
        hintKey = nil
        startedAt = nil
        endsAt = nil
    }

    private var progressFeedback: String {
        let completed = min(InputEvaluator.normalize(input).count / 2, practice.codes.count)
        let half = InputEvaluator.normalize(input).count % 2 == 1 ? " · 1/2" : ""
        return "\(completed)/\(practice.codes.count)\(half)"
    }

    private func liveRate(for count: Int) -> Int {
        guard let startedAt else { return 0 }
        let elapsed = phase == .finished
            ? duration
            : max(now().timeIntervalSince(startedAt), 0.1)
        return Int((Double(count) / (elapsed / 60)).rounded())
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
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
