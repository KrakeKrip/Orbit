import Foundation
import SwiftData

@Model
public final class OrbitTask {
    public private(set) var id: UUID
    public private(set) var title: String
    public private(set) var createdAt: Date
    public private(set) var completedAt: Date?

    public init(id: UUID = UUID(), title: String, createdAt: Date = .now, completedAt: Date? = nil) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.completedAt = completedAt
    }

    public var isCompleted: Bool {
        completedAt != nil
    }

    public func complete(at date: Date = .now) {
        guard !isCompleted else { return }
        completedAt = date
    }

    public func reopen() {
        guard isCompleted else { return }
        completedAt = nil
    }
}
