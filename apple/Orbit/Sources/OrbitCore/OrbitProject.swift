import Foundation
import SwiftData

/// Local project metadata. Task membership is a separate, later schema change.
@Model
public final class OrbitProject {
    public private(set) var id: UUID
    public private(set) var name: String
    public private(set) var createdAt: Date

    public init(id: UUID = UUID(), name: String, createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
    }

    // Only the validated store rename operation calls this setter.
    func setName(_ value: String) {
        name = value
    }
}

public enum ProjectNameError: Error, Equatable {
    case empty
    case tooLong(limit: Int)
}

public enum ProjectName {
    public static let maximumLength = 120

    public static func validated(_ rawName: String) throws -> String {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { throw ProjectNameError.empty }
        guard name.unicodeScalars.count <= maximumLength else {
            throw ProjectNameError.tooLong(limit: maximumLength)
        }
        return name
    }
}

public enum OrbitProjectStoreError: Error, Equatable {
    case projectNotFound(id: UUID)
}
