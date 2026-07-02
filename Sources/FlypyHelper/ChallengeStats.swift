import SwiftUI

struct ChallengeResult: Equatable {
    let completedAt: Date
    let duration: TimeInterval
    let correctCharacters: Int
    let typedKeys: Int
    let wrongCodes: Int
    let skippedPrompts: Int
    let hintsUsed: Int
    let score: Int
    let maxCombo: Int

    var accuracy: Double {
        let attempts = correctCharacters + wrongCodes
        guard attempts > 0 else { return 0 }
        return Double(correctCharacters) / Double(attempts)
    }

    var charactersPerMinute: Int {
        rate(for: correctCharacters)
    }

    var keysPerMinute: Int {
        rate(for: typedKeys)
    }

    private func rate(for count: Int) -> Int {
        guard duration > 0 else { return 0 }
        return Int((Double(count) / (duration / 60)).rounded())
    }
}

struct DailyChallengeStats: Codable, Identifiable, Equatable {
    var day: Date
    var rounds = 0
    var duration: TimeInterval = 0
    var correctCharacters = 0
    var typedKeys = 0
    var wrongCodes = 0
    var skippedPrompts = 0
    var hintsUsed = 0
    var bestCharactersPerMinute = 0
    var bestKeysPerMinute = 0
    var bestScore = 0
    var maxCombo = 0

    var id: Date { day }

    var accuracy: Double {
        let attempts = correctCharacters + wrongCodes
        guard attempts > 0 else { return 0 }
        return Double(correctCharacters) / Double(attempts)
    }

    var averageCharactersPerMinute: Int {
        guard duration > 0 else { return 0 }
        return Int((Double(correctCharacters) / (duration / 60)).rounded())
    }

    mutating func merge(_ result: ChallengeResult) {
        rounds += 1
        duration += result.duration
        correctCharacters += result.correctCharacters
        typedKeys += result.typedKeys
        wrongCodes += result.wrongCodes
        skippedPrompts += result.skippedPrompts
        hintsUsed += result.hintsUsed
        bestCharactersPerMinute = max(bestCharactersPerMinute, result.charactersPerMinute)
        bestKeysPerMinute = max(bestKeysPerMinute, result.keysPerMinute)
        bestScore = max(bestScore, result.score)
        maxCombo = max(maxCombo, result.maxCombo)
    }
}

@MainActor
final class ChallengeHistoryStore: ObservableObject {
    @Published private(set) var days: [DailyChallengeStats]

    private let defaults: UserDefaults
    private let calendar: Calendar
    private let storageKey = "FlypyHelper.challengeDailyStats"

    init(defaults: UserDefaults = .standard, calendar: Calendar = .autoupdatingCurrent) {
        self.defaults = defaults
        self.calendar = calendar

        if let data = defaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([DailyChallengeStats].self, from: data) {
            self.days = decoded.sorted { $0.day < $1.day }
        } else {
            self.days = []
        }
    }

    func record(_ result: ChallengeResult) {
        let day = calendar.startOfDay(for: result.completedAt)
        if let index = days.firstIndex(where: { calendar.isDate($0.day, inSameDayAs: day) }) {
            days[index].merge(result)
        } else {
            var stats = DailyChallengeStats(day: day)
            stats.merge(result)
            days.append(stats)
            days.sort { $0.day < $1.day }
        }
        save()
    }

    var today: DailyChallengeStats? {
        days.first { calendar.isDateInToday($0.day) }
    }

    var currentStreak: Int {
        guard let last = days.last?.day else { return 0 }
        let today = calendar.startOfDay(for: Date())
        guard calendar.isDate(last, inSameDayAs: today)
                || calendar.isDate(last, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: today) ?? today)
        else { return 0 }

        var streak = 1
        var cursor = last
        for stats in days.dropLast().reversed() {
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor),
                  calendar.isDate(stats.day, inSameDayAs: previous)
            else { break }
            streak += 1
            cursor = stats.day
        }
        return streak
    }

    var totalRounds: Int { days.reduce(0) { $0 + $1.rounds } }
    var totalDuration: TimeInterval { days.reduce(0) { $0 + $1.duration } }
    var allTimeBestCPM: Int { days.map(\.bestCharactersPerMinute).max() ?? 0 }
    var allTimeBestScore: Int { days.map(\.bestScore).max() ?? 0 }

    private func save() {
        guard let data = try? JSONEncoder().encode(days) else { return }
        defaults.set(data, forKey: storageKey)
    }
}
