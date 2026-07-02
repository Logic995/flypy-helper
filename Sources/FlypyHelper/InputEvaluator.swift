import Foundation

enum EvaluationResult: Equatable {
    case empty
    case progress
    case wrong(index: Int, expected: String, actual: String)
    case complete
}

enum InputEvaluator {
    static func normalize(_ input: String) -> String {
        input
            .lowercased()
            .filter { $0 >= "a" && $0 <= "z" }
    }

    static func grouped(_ input: String) -> String {
        let chars = Array(normalize(input))
        guard !chars.isEmpty else { return "" }

        return stride(from: 0, to: chars.count, by: 2)
            .map { index in
                String(chars[index..<min(index + 2, chars.count)])
            }
            .joined(separator: " ")
    }

    static func evaluate(input: String, targetCodes: [String]) -> EvaluationResult {
        let normalizedInput = normalize(input)
        guard !normalizedInput.isEmpty else { return .empty }

        let normalizedTargetCodes = targetCodes.map(normalize)
        let target = normalizedTargetCodes.joined()
        guard !target.isEmpty else { return .wrong(index: 0, expected: "", actual: normalizedInput) }

        let completedCodeCount = normalizedInput.count / 2
        let comparableCodeCount = min(completedCodeCount, normalizedTargetCodes.count)

        for index in 0..<comparableCodeCount {
            let actualCode = code(at: index, in: normalizedInput)
            let expectedCode = normalizedTargetCodes[index]

            if actualCode != expectedCode {
                return .wrong(index: index, expected: expectedCode, actual: actualCode)
            }
        }

        if normalizedInput.count > target.count {
            let extraCode = code(at: normalizedTargetCodes.count, in: normalizedInput)
            return .wrong(index: normalizedTargetCodes.count, expected: "", actual: extraCode)
        }

        if normalizedInput == target {
            return .complete
        }

        return .progress
    }

    private static func code(at index: Int, in input: String) -> String {
        let chars = Array(input)
        let start = index * 2
        guard start < chars.count else { return "" }
        return String(chars[start..<min(start + 2, chars.count)])
    }
}
