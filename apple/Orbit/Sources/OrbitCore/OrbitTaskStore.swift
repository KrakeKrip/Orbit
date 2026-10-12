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

    @discardableResult
    public func addTask(title rawTitle: String, now: Date = .now) throws -> OrbitTask {
        let title = try TaskTitle.validated(rawTitle)
        let task = OrbitTask(title: title, createdAt: now)
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
}

public enum OrbitStoreError: Error, Equatable {
    case taskNotFound(id: UUID)
}
