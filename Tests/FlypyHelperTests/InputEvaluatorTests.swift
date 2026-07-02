import XCTest
@testable import FlypyHelper

final class InputEvaluatorTests: XCTestCase {
    func testExactInputCompletes() {
        XCTAssertEqual(
            InputEvaluator.evaluate(input: "jbtm", targetCodes: ["jb", "tm"]),
            .complete
        )
    }

    func testCorrectPrefixRemainsInProgress() {
        XCTAssertEqual(
            InputEvaluator.evaluate(input: "jbt", targetCodes: ["jb", "tm"]),
            .progress
        )
    }

    func testReportsFirstMismatchInsteadOfCorrectLaterCode() {
        XCTAssertEqual(
            InputEvaluator.evaluate(input: "jxtm", targetCodes: ["jb", "tm"]),
            .wrong(index: 0, expected: "jb", actual: "jx")
        )
    }

    func testOddInputStillReportsEarlierCompletedMismatch() {
        XCTAssertEqual(
            InputEvaluator.evaluate(input: "jxt", targetCodes: ["jb", "tm"]),
            .wrong(index: 0, expected: "jb", actual: "jx")
        )
    }
}

final class PracticeContentTests: XCTestCase {
    func testEveryPracticeUnitHasOneValidCodePerCharacter() {
        for mode in PracticeMode.allCases {
            for unit in PracticeContent.units(for: mode) {
                XCTAssertEqual(
                    unit.pinyins.count,
                    unit.cleanText.count,
                    "\(mode.rawValue)「\(unit.text)」的拼音数量与汉字数量不一致"
                )

                for pinyin in unit.pinyins {
                    let code = FlypyLayout.code(for: pinyin)
                    XCTAssertNotNil(code, "「\(unit.text)」中的拼音 \(pinyin) 无法转换为双拼码")
                    XCTAssertEqual(code?.count, 2, "拼音 \(pinyin) 的双拼码长度不正确")
                }
            }
        }
    }
}
