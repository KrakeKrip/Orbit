import Foundation
import SwiftData

@Model
public final class OrbitTask {
    public private(set) var id: UUID
    public private(set) var title: String
    public private(set) var createdAt: Date
    public private(set) var completedAt: Date?
    /// Optional civil date `YYYY-MM-DD` (see `TaskPlannedDate`); nil when unset.
    /// Added as an optional field so existing stores and rows stay intact.
    public private(set) var plannedDate: String?

    public init(
        id: UUID = UUID(),
        title: String,
        createdAt: Date = .now,
        completedAt: Date? = nil,
        plannedDate: String? = nil
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.plannedDate = plannedDate
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

    /// Assigns, changes or clears (`nil`) the planned civil date.
    /// Validation of the `YYYY-MM-DD` contract lives in `TaskPlannedDate`
    /// and in the store, which rejects invalid values before mutating.
    public func setPlannedDate(_ value: String?) {
        plannedDate = value
    }
}
