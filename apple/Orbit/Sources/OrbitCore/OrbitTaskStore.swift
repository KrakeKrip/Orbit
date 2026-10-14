import Foundation
import SwiftData

@MainActor
public final class OrbitTaskStore {
    public let storeURL: URL

    private let container: ModelContainer
    private let context: ModelContext

    public init(storeURL: URL) throws {
        self.storeURL = storeURL
        let configuration = ModelConfiguration(url: storeURL, cloudKitDatabase: .none)
        self.container = try ModelContainer(for: OrbitTask.self, configurations: configuration)
        let context = ModelContext(container)
        context.autosaveEnabled = false
        self.context = context
    }

    public func tasks() throws -> [OrbitTask] {
        let fetched = try context.fetch(FetchDescriptor<OrbitTask>())
        // Explicit stable order (createdAt, then id) independent of store-level collation.
        return fetched.sorted { ($0.createdAt, $0.id) < ($1.createdAt, $1.id) }
    }

    /// NATIVE-ADD-001: creates one task together with its optional civil
    /// planned date in a single save. Backwards compatible: existing
    /// title/now calls keep working (plannedDate defaults to nil — the
    /// previous undated semantics). The accepted `TaskTitle.validated` and
    /// `TaskPlannedDate.isValid` checks run before any context mutation; on
    /// success exactly one explicit `context.save()` persists the row with
    /// one UUID/createdAt and nil completion/time/duration, with the existing
    /// rollback rethrowing a save failure. The date is always an explicit
    /// civil string from the caller — the current local day is resolved by
    /// the UI, never defaulted here.
    @discardableResult
    public func addTask(
        title rawTitle: String,
        now: Date = .now,
        plannedDate: String? = nil
    ) throws -> OrbitTask {
        let title = try TaskTitle.validated(rawTitle)
        if let plannedDate, !TaskPlannedDate.isValid(plannedDate) {
            throw TaskPlannedDateError.invalid(plannedDate)
        }
        let task = OrbitTask(title: title, createdAt: now, plannedDate: plannedDate)
        context.insert(task)
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
        return task
    }

    public func setCompleted(_ isCompleted: Bool, for id: UUID, at date: Date = .now) throws {
        let descriptor = FetchDescriptor<OrbitTask>(predicate: #Predicate { $0.id == id })
        guard let task = try context.fetch(descriptor).first else {
            throw OrbitStoreError.taskNotFound(id: id)
        }
        if isCompleted {
            task.complete(at: date)
        } else {
            task.reopen()
        }
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    /// Assigns, changes or clears (`nil`) the civil planned date of one task.
    /// Invalid values are rejected before any mutation; completion, title, id
    /// and list order are never touched, and tasks with a date stay in the Inbox.
    /// Clearing the date also clears the time interval in the same save; a date
    /// change keeps an existing interval only when the resulting derived end
    /// stays inside the product calendar range.
    public func setPlannedDate(_ plannedDate: String?, for id: UUID) throws {
        if let plannedDate, !TaskPlannedDate.isValid(plannedDate) {
            throw TaskPlannedDateError.invalid(plannedDate)
        }
        let descriptor = FetchDescriptor<OrbitTask>(predicate: #Predicate { $0.id == id })
        guard let task = try context.fetch(descriptor).first else {
            throw OrbitStoreError.taskNotFound(id: id)
        }
        if let plannedDate,
            let time = task.plannedTime, let duration = task.durationMinutes,
            TaskTimeInterval.end(plannedDate: plannedDate, plannedTime: time, durationMinutes: duration) == nil
        {
            throw TaskTimeIntervalError.endOutOfRange
        }
        task.setPlannedDate(plannedDate)
        if plannedDate == nil {
            task.setPlannedInterval(plannedTime: nil, durationMinutes: nil)
        }
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    /// Assigns, changes or clears (nil/nil) the time interval of one task as a
    /// complete pair on top of its existing planned date. The whole candidate
    /// is validated before any property changes; one explicit save with
    /// rollback on failure. Completion, title, id and order are untouched.
    public func setPlannedInterval(
        plannedTime: String?,
        durationMinutes: Int?,
        for id: UUID
    ) throws {
        if !TaskTimeInterval.isCompletePair(time: plannedTime, durationMinutes: durationMinutes) {
            throw TaskTimeIntervalError.incompletePair(
                time: plannedTime,
                durationMinutes: durationMinutes
            )
        }
        if let plannedTime, !TaskTimeInterval.isValidTime(plannedTime) {
            throw TaskTimeIntervalError.invalidTime(plannedTime)
        }
        if let durationMinutes, !TaskTimeInterval.isValidDuration(durationMinutes) {
            throw TaskTimeIntervalError.invalidDuration(durationMinutes)
        }
        // NATIVE-MIN5 write minimum: a new or changed non-nil interval must
        // be whole minutes 5...1440. The precheck runs before any property
        // mutation or save; legacy stored 1...4 remain readable through the
        // read validator above and are never rewritten by this gate.
        if let durationMinutes, !TaskTimeInterval.isWritableDuration(durationMinutes) {
            throw TaskTimeIntervalError.invalidDuration(durationMinutes)
        }
        let descriptor = FetchDescriptor<OrbitTask>(predicate: #Predicate { $0.id == id })
        guard let task = try context.fetch(descriptor).first else {
            throw OrbitStoreError.taskNotFound(id: id)
        }
        if let plannedTime, let durationMinutes {
            guard let plannedDate = task.plannedDate else {
                throw TaskTimeIntervalError.missingDate
            }
            guard
                TaskTimeInterval.end(
                    plannedDate: plannedDate,
                    plannedTime: plannedTime,
                    durationMinutes: durationMinutes
                ) != nil
            else {
                throw TaskTimeIntervalError.endOutOfRange
            }
        }
        task.setPlannedInterval(plannedTime: plannedTime, durationMinutes: durationMinutes)
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }
}

public enum OrbitStoreError: Error, Equatable {
    case taskNotFound(id: UUID)
}
