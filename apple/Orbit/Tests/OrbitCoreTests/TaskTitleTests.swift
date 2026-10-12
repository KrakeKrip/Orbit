import Foundation
import Testing
import OrbitCore

@Suite("TaskTitle validation")
struct TaskTitleTests {

    @Test("trims surrounding whitespace and newlines")
    func trims() throws {
        #expect(try TaskTitle.validated("  Купить хлеб  ") == "Купить хлеб")
        #expect(try TaskTitle.validated("\n\tПозвонить маме \n") == "Позвонить маме")
    }

    @Test("keeps internal whitespace")
    func internalWhitespace() throws {
        #expect(try TaskTitle.validated("  a  b  ") == "a  b")
    }

    @Test("empty and whitespace-only are invalid")
    func empty() {
        #expect(throws: TaskTitleError.empty) { try TaskTitle.validated("") }
        #expect(throws: TaskTitleError.empty) { try TaskTitle.validated("   ") }
        #expect(throws: TaskTitleError.empty) { try TaskTitle.validated("\n\t") }
    }

    @Test("exactly 500 Unicode scalars is valid")
    func limitBoundary() {
        let atLimit = String(repeating: "a", count: TaskTitle.maximumLength)
        #expect(atLimit.unicodeScalars.count == 500)
        #expect((try? TaskTitle.validated(atLimit)) != nil)

        let overLimit = String(repeating: "a", count: TaskTitle.maximumLength + 1)
        #expect(throws: TaskTitleError.tooLong(limit: 500)) { try TaskTitle.validated(overLimit) }
    }

    @Test("length counts Unicode scalars, not grapheme clusters")
    func scalarsNotCharacters() {
        // 👨‍👩‍👧‍👦 is one grapheme cluster of 7 Unicode scalars.
        let family = "👨‍👩‍👧‍👦"
        #expect(family.count == 1)
        #expect(family.unicodeScalars.count == 7)

        // 71 clusters = 497 scalars: valid.
        let underLimit = String(repeating: family, count: 71)
        #expect(underLimit.count == 71)
        #expect(underLimit.unicodeScalars.count == 497)
        #expect((try? TaskTitle.validated(underLimit)) != nil)

        // 72 clusters = 504 scalars: character count stays far below 500,
        // so only scalar counting can reject this input.
        let overLimit = String(repeating: family, count: 72)
        #expect(overLimit.count == 72)
        #expect(overLimit.unicodeScalars.count == 504)
        #expect(throws: TaskTitleError.tooLong(limit: 500)) { try TaskTitle.validated(overLimit) }
    }

    @Test("flag emoji (2 scalars each) respects the scalar limit")
    func flagEmoji() {
        let flag = "🇺🇦"
        #expect(flag.unicodeScalars.count == 2)
        let atLimit = String(repeating: flag, count: 250)
        #expect((try? TaskTitle.validated(atLimit)) != nil)
        let overLimit = String(repeating: flag, count: 251)
        #expect(throws: TaskTitleError.tooLong(limit: 500)) { try TaskTitle.validated(overLimit) }
    }
}
