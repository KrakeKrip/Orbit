import Foundation
import Testing
import OrbitCore

@Suite("OrbitTaskStore")
struct OrbitTaskStoreTests {

    @Test("addTask creates a unique id and stores the normalized title")
    @MainActor
    func addTask() throws {
        let dir = try TempDir.make()
        defer { TempDir.remove(dir) }
        let store = try OrbitTaskStore(storeURL: dir.appendingPathComponent("Orbit.store"))

        let at = Date(timeIntervalSince1970: 1_760_000_000)
        let first = try store.addTask(title: "  Купить хлеб  ", now: at)
        let second = try store.addTask(title: "Позвонить маме", now: at)

        #expect(first.title == "Купить хлеб")
        #expect(first.createdAt == at)
        #expect(first.id != second.id)

        let all = try store.tasks()
        #expect(all.count == 2)
        #expect(Set(all.map(\.id)) == [first.id, second.id])
    }

    @Test("empty or whitespace title throws and does not change the store")
    @MainActor
    func addEmptyRejected() throws {
        let dir = try TempDir.make()
        defer { TempDir.remove(dir) }
        let store = try OrbitTaskStore(storeURL: dir.appendingPathComponent("Orbit.store"))

        _ = try store.addTask(title: "Существующая задача", now: Date(timeIntervalSince1970: 100))

        #expect(throws: TaskTitleError.empty) { try store.addTask(title: "   ") }
        #expect(throws: TaskTitleError.empty) { try store.addTask(title: "") }

        // Existing data is untouched and the store remains usable.
        let all = try store.tasks()
        #expect(all.count == 1)
        #expect(all.first?.title == "Существующая задача")
        _ = try store.addTask(title: "Следующая задача")
        #expect(try store.tasks().count == 2)
    }

    @Test("title over 500 scalars is rejected")
    @MainActor
    func addTooLongRejected() throws {
        let dir = try TempDir.make()
        defer { TempDir.remove(dir) }
        let store = try OrbitTaskStore(storeURL: dir.appendingPathComponent("Orbit.store"))

        let overLimit = String(repeating: "b", count: 501)
        #expect(throws: TaskTitleError.tooLong(limit: 500)) { try store.addTask(title: overLimit) }
        #expect(try store.tasks().isEmpty)
    }

    @Test("setCompleted completes and reopens with explicit dates")
    @MainActor
    func completeReopen() throws {
        let dir = try TempDir.make()
        defer { TempDir.remove(dir) }
        let store = try OrbitTaskStore(storeURL: dir.appendingPathComponent("Orbit.store"))

        let createdAt = Date(timeIntervalSince1970: 1_760_000_000)
        let completedAt = createdAt.addingTimeInterval(120)
        let task = try store.addTask(title: "Задача", now: createdAt)

        try store.setCompleted(true, for: task.id, at: completedAt)
        var stored = try store.tasks()
        #expect(stored.first?.isCompleted == true)
        #expect(stored.first?.completedAt == completedAt)

        // Completing again is a no-op and keeps the original timestamp.
        try store.setCompleted(true, for: task.id, at: completedAt.addingTimeInterval(60))
        stored = try store.tasks()
        #expect(stored.first?.completedAt == completedAt)

        try store.setCompleted(false, for: task.id, at: completedAt.addingTimeInterval(180))
        stored = try store.tasks()
        #expect(stored.first?.isCompleted == false)
        #expect(stored.first?.completedAt == nil)
    }

    @Test("setCompleted for unknown id throws")
    @MainActor
    func completeUnknownId() throws {
        let dir = try TempDir.make()
        defer { TempDir.remove(dir) }
        let store = try OrbitTaskStore(storeURL: dir.appendingPathComponent("Orbit.store"))

        let missingId = UUID()
        #expect(throws: OrbitStoreError.taskNotFound(id: missingId)) {
            try store.setCompleted(true, for: missingId)
        }
    }

    @Test("stable order: createdAt first, then id")
    @MainActor
    func stableOrder() throws {
        let dir = try TempDir.make()
        defer { TempDir.remove(dir) }
        let store = try OrbitTaskStore(storeURL: dir.appendingPathComponent("Orbit.store"))

        let earlier = Date(timeIntervalSince1970: 1_760_000_000)
        let later = earlier.addingTimeInterval(10)

        let laterTask = try store.addTask(title: "Позже", now: later)
        let earlierTask = try store.addTask(title: "Раньше", now: earlier)
        var all = try store.tasks()
        #expect(all.map(\.id) == [earlierTask.id, laterTask.id])

        // Equal createdAt falls back to id order across the whole tie group.
        let a = try store.addTask(title: "A", now: earlier)
        let b = try store.addTask(title: "B", now: earlier)
        all = try store.tasks()
        let tieGroup = [earlierTask.id, a.id, b.id].sorted { $0.uuidString < $1.uuidString }
        #expect(all.map(\.id) == tieGroup + [laterTask.id])
    }

    @Test("disk reopen: a new container on the same URL keeps UUID, title and completion")
    @MainActor
    func diskReopenRegression() throws {
        let dir = try TempDir.make()
        defer { TempDir.remove(dir) }
        let storeURL = dir.appendingPathComponent("Orbit.store")

        var firstStore: OrbitTaskStore? = try OrbitTaskStore(storeURL: storeURL)
        let createdAt = Date(timeIntervalSince1970: 1_760_000_000)
        let completedAt = createdAt.addingTimeInterval(300)
        let openTask = try firstStore?.addTask(title: "Открытая задача", now: createdAt)
        let doneTask = try firstStore?.addTask(title: "Готовая задача", now: createdAt.addingTimeInterval(5))
        try firstStore?.setCompleted(true, for: doneTask?.id ?? UUID(), at: completedAt)
        firstStore = nil

        #expect(FileManager.default.fileExists(atPath: storeURL.path))

        let reopened = try OrbitTaskStore(storeURL: storeURL)
        let all = try reopened.tasks()
        #expect(all.count == 2)

        let reopenedOpen = all.first { $0.id == openTask?.id }
        let reopenedDone = all.first { $0.id == doneTask?.id }
        #expect(reopenedOpen?.title == "Открытая задача")
        #expect(reopenedOpen?.createdAt == createdAt)
        #expect(reopenedOpen?.completedAt == nil)
        #expect(reopenedDone?.title == "Готовая задача")
        #expect(reopenedDone?.createdAt == createdAt.addingTimeInterval(5))
        #expect(reopenedDone?.completedAt == completedAt)
        #expect(reopenedDone?.isCompleted == true)
    }

    @Test("failed open throws and creates no store")
    @MainActor
    func openFailure() throws {
        let dir = try TempDir.make()
        defer { TempDir.remove(dir) }

        // The parent of the requested store path is a regular file:
        // opening a store underneath it must fail and must not create anything.
        let blocker = dir.appendingPathComponent("blocker")
        try Data("not a directory".utf8).write(to: blocker)
        let storeURL = blocker.appendingPathComponent("nested").appendingPathComponent("Orbit.store")

        #expect(throws: (any Error).self) {
            _ = try OrbitTaskStore(storeURL: storeURL)
        }
        #expect(!FileManager.default.fileExists(atPath: storeURL.path))
        #expect(!FileManager.default.fileExists(atPath: blocker.appendingPathComponent("nested").path))
    }
}
