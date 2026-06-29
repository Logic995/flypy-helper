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

        let target = targetCodes.joined()
        guard !target.isEmpty else { return .wrong(index: 0, expected: "", actual: normalizedInput) }

        if normalizedInput == target {
            return .complete
        }

        if normalizedInput.count > target.count {
            let index = max(0, min(targetCodes.count - 1, targetCodes.count))
            return .wrong(index: index, expected: "", actual: String(normalizedInput.suffix(2)))
        }

        if normalizedInput.count % 2 == 1 {
            return .progress
        }

        let currentIndex = max(0, normalizedInput.count / 2 - 1)
        guard currentIndex < targetCodes.count else {
            return .wrong(index: targetCodes.count - 1, expected: "", actual: String(normalizedInput.suffix(2)))
        }

        let actualCode = code(at: currentIndex, in: normalizedInput)
        let expectedCode = targetCodes[currentIndex]

        if actualCode == expectedCode, target.hasPrefix(normalizedInput) {
            return .progress
        }

        return .wrong(index: currentIndex, expected: expectedCode, actual: actualCode)
    }

    private static func code(at index: Int, in input: String) -> String {
        let chars = Array(input)
        let start = index * 2
        guard start < chars.count else { return "" }
        return String(chars[start..<min(start + 2, chars.count)])
    }
}
