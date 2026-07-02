import XCTest
@testable import FlypyHelper

@MainActor
final class ChallengeEngineTests: XCTestCase {
    private let prompt = PracticeUnit(
        mode: .phrase,
        title: "词组",
        text: "今天",
        pinyins: ["jin", "tian"]
    )

    func testCorrectCodesBuildScoreAndCombo() {
        let context = makeContext()
        let engine = context.engine
        engine.start()

        type("jbtm", into: engine)

        XCTAssertEqual(engine.correctCharacters, 2)
        XCTAssertEqual(engine.combo, 2)
        XCTAssertEqual(engine.maxCombo, 2)
        XCTAssertEqual(engine.score, 200)
        XCTAssertEqual(engine.typedKeys, 4)
        XCTAssertEqual(engine.wrongCodes, 0)
    }

    func testWrongCodeResetsComboAndRaisesFinalWeight() {
        let context = makeContext()
        let engine = context.engine
        engine.start()
        type("jb", into: engine)
        XCTAssertEqual(engine.combo, 1)

        type("tx", into: engine)

        XCTAssertEqual(engine.combo, 0)
        XCTAssertEqual(engine.wrongCodes, 1)
        XCTAssertEqual(engine.input, "jb")
        XCTAssertEqual(context.profile.errorWeights["ian"], 2)
    }

    func testComboMultiplierChangesAtTenCharacters() {
        let context = makeContext()
        let engine = context.engine
        engine.start()

        for _ in 0..<5 {
            type("jbtm", into: engine)
        }

        XCTAssertEqual(engine.correctCharacters, 10)
        XCTAssertEqual(engine.combo, 10)
        XCTAssertEqual(engine.score, 1_025)
    }

    func testHintAndSkipResetComboAndAreCounted() {
        let context = makeContext()
        let engine = context.engine
        engine.start()
        type("jb", into: engine)

        engine.handle(.tab)

        XCTAssertEqual(engine.hintsUsed, 1)
        XCTAssertEqual(engine.combo, 0)
        XCTAssertEqual(engine.hintKey, "t")

        engine.handle(.space)

        XCTAssertEqual(engine.skippedPrompts, 1)
        XCTAssertTrue(engine.input.isEmpty)
    }

    func testRoundFinishesOnceAndPersistsDailyStats() {
        var currentDate = Date(timeIntervalSince1970: 1_800_000_000)
        let context = makeContext(now: { currentDate })
        let engine = context.engine
        engine.start()
        type("jbtm", into: engine)

        currentDate = currentDate.addingTimeInterval(60)
        engine.tick(at: currentDate)
        engine.tick(at: currentDate.addingTimeInterval(1))

        XCTAssertEqual(engine.phase, .finished)
        XCTAssertEqual(engine.timeRemaining, 0)
        XCTAssertEqual(context.history.totalRounds, 1)
        XCTAssertEqual(context.history.days.first?.correctCharacters, 2)
        XCTAssertEqual(engine.latestResult?.charactersPerMinute, 2)
    }

    func testCancelDoesNotPersistRound() {
        let context = makeContext()
        context.engine.start()
        type("jbtm", into: context.engine)
        XCTAssertEqual(context.engine.score, 200)

        context.engine.cancel()

        XCTAssertEqual(context.engine.phase, .ready)
        XCTAssertEqual(context.engine.score, 0)
        XCTAssertEqual(context.engine.combo, 0)
        XCTAssertEqual(context.engine.correctCharacters, 0)
        XCTAssertEqual(context.engine.typedKeys, 0)
        XCTAssertNil(context.engine.latestResult)
        XCTAssertEqual(context.history.totalRounds, 0)
    }

    private func makeContext(now: @escaping () -> Date = Date.init) -> (
        engine: ChallengeEngine,
        profile: PracticeProfile,
        history: ChallengeHistoryStore
    ) {
        let suiteName = "FlypyHelperTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let profile = PracticeProfile(defaults: defaults)
        let history = ChallengeHistoryStore(defaults: defaults)
        let prompt = self.prompt
        let engine = ChallengeEngine(
            profile: profile,
            history: history,
            duration: 60,
            automaticallyTicks: false,
            now: now,
            promptProvider: { _, _ in prompt }
        )
        return (engine, profile, history)
    }

    private func type(_ text: String, into engine: ChallengeEngine) {
        for character in text {
            engine.handle(.letter(String(character)))
        }
    }
}

@MainActor
final class ChallengeHistoryStoreTests: XCTestCase {
    func testResultsMergeByDayAndPreserveBestValues() {
        let suiteName = "FlypyHelperTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let store = ChallengeHistoryStore(defaults: defaults)
        let date = Date()

        store.record(result(at: date, correct: 20, wrong: 2, score: 2_000))
        store.record(result(at: date.addingTimeInterval(120), correct: 25, wrong: 3, score: 2_800))

        XCTAssertEqual(store.days.count, 1)
        XCTAssertEqual(store.days[0].rounds, 2)
        XCTAssertEqual(store.days[0].correctCharacters, 45)
        XCTAssertEqual(store.days[0].wrongCodes, 5)
        XCTAssertEqual(store.days[0].bestScore, 2_800)
        XCTAssertEqual(store.totalRounds, 2)
    }

    func testConsecutiveDaysProduceStreak() {
        let suiteName = "FlypyHelperTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let calendar = Calendar.autoupdatingCurrent
        let store = ChallengeHistoryStore(defaults: defaults, calendar: calendar)
        let today = calendar.startOfDay(for: Date())

        store.record(result(at: calendar.date(byAdding: .day, value: -2, to: today)!, correct: 10, wrong: 0, score: 1_000))
        store.record(result(at: calendar.date(byAdding: .day, value: -1, to: today)!, correct: 10, wrong: 0, score: 1_000))
        store.record(result(at: today, correct: 10, wrong: 0, score: 1_000))

        XCTAssertEqual(store.currentStreak, 3)
    }

    private func result(at date: Date, correct: Int, wrong: Int, score: Int) -> ChallengeResult {
        ChallengeResult(
            completedAt: date,
            duration: 60,
            correctCharacters: correct,
            typedKeys: (correct + wrong) * 2,
            wrongCodes: wrong,
            skippedPrompts: 0,
            hintsUsed: 0,
            score: score,
            maxCombo: correct
        )
    }
}
