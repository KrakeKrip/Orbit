import Foundation
import Testing
import OrbitCore

@Suite("Task project membership")
struct TaskProjectTests {
    @Test("Assign, move, clear and reopen preserve every other task field")
    @MainActor func assignment() throws {
        let dir = try TempDir.make(); defer { TempDir.remove(dir) }
        let url = dir.appendingPathComponent("test.store")
        let id: UUID; let projectID: UUID
        let at = Date(timeIntervalSince1970: 100)
        do {
            let s = try OrbitTaskStore(storeURL: url)
            let a = try s.addProject(name: "Работа")
            let b = try s.addProject(name: "Личное")
            let t = try s.addTask(title: "Задача", now: at, plannedDate: "2026-10-16", plannedTime: "23:08", durationMinutes: 100)
            id = t.id; projectID = b.id
            let other = try s.addTask(title: "Другая")
            try s.setCompleted(true, for: id, at: at)
            try s.setProject(a.id, for: id)
            try s.setProject(a.id, for: id)
            try s.setProject(nil, for: id)
            #expect(t.projectID == nil)
            try s.setProject(b.id, for: id)
            #expect(other.projectID == nil)
            #expect(t.id == id && t.createdAt == at && t.completedAt == at)
            #expect(t.title == "Задача" && t.plannedDate == "2026-10-16")
            #expect(t.plannedTime == "23:08" && t.durationMinutes == 100)
        }
        let reopened = try OrbitTaskStore(storeURL: url)
        let t = try #require(reopened.tasks().first { $0.id == id })
        #expect(t.projectID == projectID)
        #expect(t.completedAt == at && t.plannedTime == "23:08" && t.durationMinutes == 100)
    }

    @Test("Missing task/project refuse without mutation or partial create; retry works")
    @MainActor func refusals() throws {
        let dir = try TempDir.make(); defer { TempDir.remove(dir) }
        let s = try OrbitTaskStore(storeURL: dir.appendingPathComponent("test.store"))
        let p = try s.addProject(name: "Работа")
        let t = try s.addTask(title: "Изначальная", projectID: p.id)
        let missing = UUID()
        #expect(throws: OrbitProjectStoreError.projectNotFound(id: missing)) { try s.setProject(missing, for: t.id) }
        #expect(throws: OrbitStoreError.taskNotFound(id: missing)) { try s.setProject(p.id, for: missing) }
        #expect(throws: OrbitProjectStoreError.projectNotFound(id: missing)) { try s.addTask(title: "Нет", projectID: missing) }
        #expect(try s.tasks().count == 1)
        #expect(t.projectID == p.id)
        let fresh = try s.addTask(title: "Новая", plannedDate: "2026-10-16", plannedTime: "09:08", durationMinutes: 6, projectID: p.id)
        #expect(fresh.projectID == p.id && fresh.durationMinutes == 6)
        #expect(OrbitTask(title: "Старый initializer").projectID == nil)
        #expect(try s.addTask(title: "Без проекта").projectID == nil)
    }

    @Test("Actual previous-source project/task fixture upgrades without losing fields", .enabled(if: ProcessInfo.processInfo.environment["ORBIT_MEMBERSHIP_FIXTURE"] != nil))
    @MainActor func previousUpgrade() throws {
        let path = try #require(ProcessInfo.processInfo.environment["ORBIT_MEMBERSHIP_FIXTURE"])
        let dir = try TempDir.make(); defer { TempDir.remove(dir) }
        let url = dir.appendingPathComponent("upgrade.store")
        for suffix in ["", "-wal", "-shm"] {
            let source = URL(fileURLWithPath: path + suffix)
            if FileManager.default.fileExists(atPath: source.path) {
                try FileManager.default.copyItem(at: source, to: URL(fileURLWithPath: url.path + suffix))
            }
        }
        let oracle = try #require(JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: path + ".json"))) as? [String: String])
        let s = try OrbitTaskStore(storeURL: url)
        let p = try #require(s.projects().first)
        #expect(p.name == "Старый проект" && p.id.uuidString == oracle["project"])
        #expect(p.createdAt == Date(timeIntervalSince1970: 100))
        let t = try #require(s.tasks().first)
        #expect(t.projectID == nil && t.title == "Прежняя задача" && t.id.uuidString == oracle["task"])
        #expect(t.createdAt == Date(timeIntervalSince1970: 100) && t.completedAt == Date(timeIntervalSince1970: 200))
        #expect(t.plannedDate == "2026-10-16" && t.plannedTime == "23:08" && t.durationMinutes == 100)
        try s.setProject(p.id, for: t.id)
        let reopened = try OrbitTaskStore(storeURL: url)
        #expect(try reopened.tasks().first?.projectID == p.id)
    }
}
