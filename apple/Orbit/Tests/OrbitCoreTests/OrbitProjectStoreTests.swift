import Foundation
import SwiftData
import Testing
import OrbitCore

@Suite("OrbitProjectStore")
struct OrbitProjectStoreTests {
    @Test("Project names trim, preserve Unicode, and count scalars at the boundary")
    func names() throws {
        #expect(try ProjectName.validated(" \n Личный проект 👩🏽‍💻 \t") == "Личный проект 👩🏽‍💻")
        #expect(try ProjectName.validated(String(repeating: "я", count: 120)).unicodeScalars.count == 120)
        #expect(throws: ProjectNameError.empty) { try ProjectName.validated(" \n\t") }
        #expect(throws: ProjectNameError.tooLong(limit: 120)) {
            try ProjectName.validated(String(repeating: "я", count: 121))
        }
        // A grapheme can contain multiple scalars; this is not a character limit.
        #expect(throws: ProjectNameError.tooLong(limit: 120)) {
            try ProjectName.validated(String(repeating: "e\u{301}", count: 61))
        }
    }

    @Test("Create allows duplicate names, unique identities and deterministic ordering")
    @MainActor
    func createAndOrder() throws {
        let dir = try TempDir.make()
        defer { TempDir.remove(dir) }
        let store = try OrbitTaskStore(storeURL: dir.appendingPathComponent("Orbit.store"))
        #expect(try store.projects().isEmpty)
        let date = Date(timeIntervalSince1970: 100)
        let a = try store.addProject(name: " Работа ", now: date)
        let b = try store.addProject(name: "Работа", now: date)
        let c = try store.addProject(name: "Раньше", now: date.addingTimeInterval(-1))
        let values = try store.projects()
        #expect(a.id != b.id)
        #expect(a.name == "Работа")
        #expect(a.createdAt == date)
        #expect(values.map(\.id) == [c.id] + [a.id, b.id].sorted())
        #expect(try store.tasks().isEmpty)
    }

    @Test("Invalid create and rename do not mutate persisted state; valid retry succeeds")
    @MainActor
    func validationAndRetry() throws {
        let dir = try TempDir.make()
        defer { TempDir.remove(dir) }
        let url = dir.appendingPathComponent("Orbit.store")
        let store = try OrbitTaskStore(storeURL: url)
        let project = try store.addProject(name: "Первый")
        for bad in ["", " \n\t", String(repeating: "я", count: 121)] {
            #expect(throws: ProjectNameError.self) { try store.addProject(name: bad) }
            #expect(throws: ProjectNameError.self) { try store.renameProject(name: bad, for: project.id) }
        }
        let reopened = try OrbitTaskStore(storeURL: url)
        #expect(try reopened.projects().map(\.name) == ["Первый"])
        let renamed = try store.renameProject(name: " Второй ", for: project.id)
        #expect(renamed.id == project.id)
        #expect(renamed.name == "Второй")
        #expect(try store.addProject(name: "Повтор").name == "Повтор")
    }

    @Test("Rename changes only target name; identical rename and missing ID are safe")
    @MainActor
    func renameAndMissing() throws {
        let dir = try TempDir.make()
        defer { TempDir.remove(dir) }
        let url = dir.appendingPathComponent("Orbit.store")
        let at = Date(timeIntervalSince1970: 100)
        var expectedIDs: [UUID] = []
        do {
            let store = try OrbitTaskStore(storeURL: url)
            let a = try store.addProject(name: "Дом", now: at)
            let b = try store.addProject(name: "Работа", now: at.addingTimeInterval(1))
            expectedIDs = [a.id, b.id]
            let missing = UUID()
            #expect(throws: OrbitProjectStoreError.projectNotFound(id: missing)) {
                try store.renameProject(name: "Нет", for: missing)
            }
            try store.renameProject(name: " Дом ", for: a.id)
            #expect(a.name == "Дом")
            try store.renameProject(name: "Семья", for: a.id)
            #expect(a.createdAt == at)
            #expect(b.name == "Работа")
        }
        let reopened = try OrbitTaskStore(storeURL: url)
        let values = try reopened.projects()
        #expect(values.map(\.id) == expectedIDs)
        #expect(values.map(\.name) == ["Семья", "Работа"])
        #expect(values.map(\.createdAt) == [at, at.addingTimeInterval(1)])
    }

    @Test("Task-only disk upgrade preserves every task field through project writes and reopen")
    @MainActor
    func upgrade() throws {
        let dir = try TempDir.make()
        defer { TempDir.remove(dir) }
        let url = dir.appendingPathComponent("Orbit.store")
        let expected: [ProjectTaskSnapshot]
        if let fixture = ProcessInfo.processInfo.environment["ORBIT_PRJ_PREVIOUS_FIXTURE"] {
            // A dedicated additional run supplies a store made by the actual previous commit.
            let source = URL(fileURLWithPath: fixture)
            for suffix in ["", "-wal", "-shm"] {
                let part = URL(fileURLWithPath: source.path + suffix)
                if FileManager.default.fileExists(atPath: part.path) {
                    try FileManager.default.copyItem(at: part, to: URL(fileURLWithPath: url.path + suffix))
                }
            }
            expected = try JSONDecoder().decode([ProjectTaskSnapshot].self,
                from: Data(contentsOf: URL(fileURLWithPath: source.path + ".json")))
        } else {
            expected = try makeTaskOnlyStore(url: url)
        }
        let projectID: UUID
        do {
            let store = try OrbitTaskStore(storeURL: url)
            #expect(try store.projects().isEmpty)
            #expect(try store.tasks().map(ProjectTaskSnapshot.init) == expected)
            let p = try store.addProject(name: "После обновления")
            projectID = p.id
            try store.renameProject(name: "Сохранённый проект", for: p.id)
            #expect(try store.tasks().map(ProjectTaskSnapshot.init) == expected)
        }
        let reopened = try OrbitTaskStore(storeURL: url)
        #expect(try reopened.tasks().map(ProjectTaskSnapshot.init) == expected)
        #expect(try reopened.projects().map(\.id) == [projectID])
        #expect(try reopened.projects().map(\.name) == ["Сохранённый проект"])
        // The original task API remains usable on the upgraded store.
        let fresh = try reopened.addTask(title: "Новая задача", plannedDate: "2026-10-16")
        try reopened.setCompleted(true, for: fresh.id)
        try reopened.renameTask(title: "Переименована", for: fresh.id)
        try reopened.deleteTask(for: fresh.id)
        #expect(try reopened.tasks().map(ProjectTaskSnapshot.init) == expected)
        #expect(try reopened.projects().first?.id == projectID)
    }

    @MainActor
    private func makeTaskOnlyStore(url: URL) throws -> [ProjectTaskSnapshot] {
        // OrbitTask is unchanged; this is the exact task-only schema used before PRJ001.
        let config = ModelConfiguration(url: url, cloudKitDatabase: .none)
        let container = try ModelContainer(for: OrbitTask.self, configurations: config)
        let context = ModelContext(container)
        context.autosaveEnabled = false
        let at = Date(timeIntervalSince1970: 100)
        let rows = [
            OrbitTask(title: "Без даты", createdAt: at),
            OrbitTask(title: "Завершена", createdAt: at.addingTimeInterval(1), completedAt: at.addingTimeInterval(20), plannedDate: "2026-10-16"),
            OrbitTask(title: "Ночью", createdAt: at.addingTimeInterval(2), plannedDate: "2026-10-16", plannedTime: "23:30", durationMinutes: 100),
            OrbitTask(title: "Legacy", createdAt: at.addingTimeInterval(3), plannedDate: "2026-10-16", plannedTime: "09:08", durationMinutes: 1)
        ]
        for row in rows { context.insert(row) }
        try context.save()
        return rows.map(ProjectTaskSnapshot.init)
    }
}

private struct ProjectTaskSnapshot: Codable, Equatable {
    let id: UUID
    let title: String
    let createdAt: Date
    let completedAt: Date?
    let plannedDate: String?
    let plannedTime: String?
    let durationMinutes: Int?

    init(_ task: OrbitTask) {
        id = task.id; title = task.title; createdAt = task.createdAt
        completedAt = task.completedAt; plannedDate = task.plannedDate
        plannedTime = task.plannedTime; durationMinutes = task.durationMinutes
    }
}
