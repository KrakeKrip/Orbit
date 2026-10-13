import Foundation

public enum TaskTitleError: Error, Equatable {
    case empty
    case tooLong(limit: Int)
}

public enum TaskTitle {
    /// Maximum length counted in Unicode scalars (not grapheme clusters).
    public static let maximumLength = 500

    /// Trims surrounding whitespace/newlines and validates the 1...500 Unicode-scalar limit.
    /// Returns the normalized title or throws `TaskTitleError`.
    public static func validated(_ rawTitle: String) throws -> String {
        let title = rawTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let scalarCount = title.unicodeScalars.count
        if scalarCount == 0 {
            throw TaskTitleError.empty
        }
        if scalarCount > maximumLength {
            throw TaskTitleError.tooLong(limit: maximumLength)
        }
        return title
    }
}
