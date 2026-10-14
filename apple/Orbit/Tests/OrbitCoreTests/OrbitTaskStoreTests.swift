import Foundation
import SwiftData
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

    // MARK: - NATIVE-ADD-001: atomic creation with an optional planned date

    @Test("addTask with plannedDate creates the task and its date in one row")
    @MainActor
    func addDatedTask() throws {
        let dir = try TempDir.make()
        defer { TempDir.remove(dir) }
        let store = try OrbitTaskStore(storeURL: dir.appendingPathComponent("Orbit.store"))

        let at = Date(timeIntervalSince1970: 1_760_000_000)
        let task = try store.addTask(title: "  Купить хлеб  ", now: at, plannedDate: "2026-10-14")

        #expect(task.title == "Купить хлеб")
        #expect(task.createdAt == at)
        #expect(task.plannedDate == "2026-10-14")
        #expect(task.completedAt == nil)
        #expect(task.plannedTime == nil)
        #expect(task.durationMinutes == nil)

        let all = try store.tasks()
        #expect(all.count == 1)
        #expect(all.first?.id == task.id)
        #expect(all.first?.plannedDate == "2026-10-14")
    }

    @Test("addTask without plannedDate keeps the previous undated semantics")
    @MainActor
    func addUndatedTask() throws {
        let dir = try TempDir.make()
        defer { TempDir.remove(dir) }
        let store = try OrbitTaskStore(storeURL: dir.appendingPathComponent("Orbit.store"))

        let at = Date(timeIntervalSince1970: 1_760_000_000)
        let implicit = try store.addTask(title: "Без даты", now: at)
        let explicitNil = try store.addTask(title: "Явно без даты", now: at, plannedDate: nil)

        for task in [implicit, explicitNil] {
            #expect(task.plannedDate == nil)
            #expect(task.completedAt == nil)
            #expect(task.plannedTime == nil)
            #expect(task.durationMinutes == nil)
        }
        #expect(try store.tasks().count == 2)
    }

    @Test("disk reopen keeps the created UUID and date with empty interval and completion")
    @MainActor
    func datedDiskReopen() throws {
        let dir = try TempDir.make()
        defer { TempDir.remove(dir) }
        let storeURL = dir.appendingPathComponent("Orbit.store")

        var firstStore: OrbitTaskStore? = try OrbitTaskStore(storeURL: storeURL)
        let createdAt = Date(timeIntervalSince1970: 1_760_000_000)
        let created = try firstStore?.addTask(title: "Датированная", now: createdAt, plannedDate: "2026-10-14")
        firstStore = nil

        let second = try OrbitTaskStore(storeURL: storeURL)
        let stored = try second.tasks()
        #expect(stored.count == 1)
        #expect(stored.first?.id == created?.id)
        #expect(stored.first?.title == "Датированная")
        #expect(stored.first?.createdAt == createdAt)
        #expect(stored.first?.plannedDate == "2026-10-14")
        #expect(stored.first?.completedAt == nil)
        #expect(stored.first?.plannedTime == nil)
        #expect(stored.first?.durationMinutes == nil)
    }

    @Test("invalid planned date is rejected before insert; existing rows stay and retry works")
    @MainActor
    func addDatedInvalidDateRejected() throws {
        let dir = try TempDir.make()
        defer { TempDir.remove(dir) }
        let store = try OrbitTaskStore(storeURL: dir.appendingPathComponent("Orbit.store"))

        _ = try store.addTask(title: "Существующая задача", now: Date(timeIntervalSince1970: 100), plannedDate: "2026-01-02")

        #expect(throws: TaskPlannedDateError.invalid("2026-13-40")) {
            try store.addTask(title: "Новая", now: Date(timeIntervalSince1970: 200), plannedDate: "2026-13-40")
        }

        let all = try store.tasks()
        #expect(all.count == 1)
        #expect(all.first?.title == "Существующая задача")
        #expect(all.first?.plannedDate == "2026-01-02")

        // The store remains usable for a valid dated retry.
        let retry = try store.addTask(title: "Новая", now: Date(timeIntervalSince1970: 200), plannedDate: "2026-10-14")
        #expect(retry.plannedDate == "2026-10-14")
        #expect(try store.tasks().count == 2)
    }

    @Test("invalid title with a date is rejected before insert; existing rows stay and retry works")
    @MainActor
    func addDatedInvalidTitleRejected() throws {
        let dir = try TempDir.make()
        defer { TempDir.remove(dir) }
        let store = try OrbitTaskStore(storeURL: dir.appendingPathComponent("Orbit.store"))

        _ = try store.addTask(title: "Существующая задача", now: Date(timeIntervalSince1970: 100), plannedDate: "2026-01-02")

        #expect(throws: TaskTitleError.empty) {
            try store.addTask(title: "   ", now: Date(timeIntervalSince1970: 200), plannedDate: "2026-10-14")
        }

        let all = try store.tasks()
        #expect(all.count == 1)
        #expect(all.first?.title == "Существующая задача")
        #expect(all.first?.plannedDate == "2026-01-02")

        let retry = try store.addTask(title: "Повтор", now: Date(timeIntervalSince1970: 200), plannedDate: "2026-10-14")
        #expect(retry.title == "Повтор")
        #expect(retry.plannedDate == "2026-10-14")
        #expect(try store.tasks().count == 2)
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

    @Test("new tasks are created without a planned date")
    @MainActor
    func createdWithoutPlannedDate() throws {
        let dir = try TempDir.make()
        defer { TempDir.remove(dir) }
        let store = try OrbitTaskStore(storeURL: dir.appendingPathComponent("Orbit.store"))

        let task = try store.addTask(title: "Без даты")
        #expect(task.plannedDate == nil)
    }

    @Test("setPlannedDate assigns, changes and clears with explicit save")
    @MainActor
    func assignChangeClear() throws {
        let dir = try TempDir.make()
        defer { TempDir.remove(dir) }
        let store = try OrbitTaskStore(storeURL: dir.appendingPathComponent("Orbit.store"))

        let createdAt = Date(timeIntervalSince1970: 1_760_000_000)
        let task = try store.addTask(title: "Задача с датой", now: createdAt)

        try store.setPlannedDate("2026-10-20", for: task.id)
        var stored = try store.tasks()
        #expect(stored.count == 1)
        #expect(stored.first?.plannedDate == "2026-10-20")
        #expect(stored.first?.isCompleted == false)
        #expect(stored.first?.title == "Задача с датой")

        // Changing to another valid value overwrites the previous one.
        try store.setPlannedDate("2026-11-01", for: task.id)
        stored = try store.tasks()
        #expect(stored.first?.plannedDate == "2026-11-01")

        // Repeating the same value is safe and does not duplicate the task.
        try store.setPlannedDate("2026-11-01", for: task.id)
        stored = try store.tasks()
        #expect(stored.count == 1)
        #expect(stored.first?.plannedDate == "2026-11-01")

        // Clearing returns the field to nil.
        try store.setPlannedDate(nil, for: task.id)
        stored = try store.tasks()
        #expect(stored.first?.plannedDate == nil)
    }

    @Test("invalid planned date is rejected before mutation and keeps the old value")
    @MainActor
    func invalidDateRejected() throws {
        let dir = try TempDir.make()
        defer { TempDir.remove(dir) }
        let store = try OrbitTaskStore(storeURL: dir.appendingPathComponent("Orbit.store"))

        let task = try store.addTask(title: "Задача")
        try store.setPlannedDate("2026-10-20", for: task.id)

        #expect(throws: TaskPlannedDateError.invalid("2026-13-40")) {
            try store.setPlannedDate("2026-13-40", for: task.id)
        }
        #expect(throws: TaskPlannedDateError.invalid("not-a-date")) {
            try store.setPlannedDate("not-a-date", for: task.id)
        }
        // The previously assigned value survives invalid attempts.
        let stored = try store.tasks()
        #expect(stored.first?.plannedDate == "2026-10-20")
        #expect(stored.count == 1)
    }

    @Test("setPlannedDate for unknown id throws taskNotFound")
    @MainActor
    func plannedDateUnknownId() throws {
        let dir = try TempDir.make()
        defer { TempDir.remove(dir) }
        let store = try OrbitTaskStore(storeURL: dir.appendingPathComponent("Orbit.store"))

        let missingId = UUID()
        #expect(throws: OrbitStoreError.taskNotFound(id: missingId)) {
            try store.setPlannedDate("2026-10-20", for: missingId)
        }
    }

    @Test("disk reopen keeps the planned date alongside older fields")
    @MainActor
    func plannedDateDiskReopen() throws {
        let dir = try TempDir.make()
        defer { TempDir.remove(dir) }
        let storeURL = dir.appendingPathComponent("Orbit.store")

        var firstStore: OrbitTaskStore? = try OrbitTaskStore(storeURL: storeURL)
        let completedAt = Date(timeIntervalSince1970: 1_760_000_100)
        let dated = try firstStore?.addTask(title: "С датой", now: Date(timeIntervalSince1970: 1_760_000_000))
        let plain = try firstStore?.addTask(title: "Без даты", now: Date(timeIntervalSince1970: 1_760_000_005))
        try firstStore?.setPlannedDate("2026-12-31", for: dated?.id ?? UUID())
        try firstStore?.setCompleted(true, for: plain?.id ?? UUID(), at: completedAt)
        firstStore = nil

        let reopened = try OrbitTaskStore(storeURL: storeURL)
        let all = try reopened.tasks()
        #expect(all.count == 2)
        let reopenedDated = all.first { $0.id == dated?.id }
        let reopenedPlain = all.first { $0.id == plain?.id }
        #expect(reopenedDated?.plannedDate == "2026-12-31")
        #expect(reopenedDated?.isCompleted == false)
        #expect(reopenedPlain?.plannedDate == nil)
        #expect(reopenedPlain?.isCompleted == true)

        // Assigning a date does not hide the task or reorder the list.
        try reopened.setPlannedDate("2027-01-05", for: plain?.id ?? UUID())
        let afterAssign = try reopened.tasks()
        #expect(afterAssign.count == 2)
        #expect(afterAssign.map(\.id) == [dated?.id, plain?.id].compactMap { $0 })
    }

    // MARK: - Time interval (NATIVE-004)

    @Test("new tasks are created without a time interval")
    @MainActor
    func createdWithoutInterval() throws {
        let dir = try TempDir.make()
        defer { TempDir.remove(dir) }
        let store = try OrbitTaskStore(storeURL: dir.appendingPathComponent("Orbit.store"))

        let task = try store.addTask(title: "Без интервала")
        #expect(task.plannedTime == nil)
        #expect(task.durationMinutes == nil)
    }

    @Test("setPlannedInterval assigns, changes, repeats and clears on a dated task")
    @MainActor
    func intervalAssignChangeClear() throws {
        let dir = try TempDir.make()
        defer { TempDir.remove(dir) }
        let store = try OrbitTaskStore(storeURL: dir.appendingPathComponent("Orbit.store"))

        let task = try store.addTask(title: "С интервалом")
        try store.setPlannedDate("2026-10-20", for: task.id)

        try store.setPlannedInterval(plannedTime: "09:30", durationMinutes: 90, for: task.id)
        var stored = try store.tasks()
        #expect(stored.count == 1)
        #expect(stored.first?.plannedTime == "09:30")
        #expect(stored.first?.durationMinutes == 90)
        #expect(stored.first?.plannedDate == "2026-10-20")
        #expect(stored.first?.isCompleted == false)
        #expect(stored.first?.title == "С интервалом")

        try store.setPlannedInterval(plannedTime: "10:15", durationMinutes: 45, for: task.id)
        stored = try store.tasks()
        #expect(stored.first?.plannedTime == "10:15")
        #expect(stored.first?.durationMinutes == 45)

        // Repeating the same interval is safe and does not duplicate the task.
        try store.setPlannedInterval(plannedTime: "10:15", durationMinutes: 45, for: task.id)
        stored = try store.tasks()
        #expect(stored.count == 1)
        #expect(stored.first?.plannedTime == "10:15")

        // Clearing keeps the date.
        try store.setPlannedInterval(plannedTime: nil, durationMinutes: nil, for: task.id)
        stored = try store.tasks()
        #expect(stored.first?.plannedTime == nil)
        #expect(stored.first?.durationMinutes == nil)
        #expect(stored.first?.plannedDate == "2026-10-20")
    }

    @Test("incomplete pair is rejected before mutation and keeps old values")
    @MainActor
    func incompletePairRejected() throws {
        let dir = try TempDir.make()
        defer { TempDir.remove(dir) }
        let store = try OrbitTaskStore(storeURL: dir.appendingPathComponent("Orbit.store"))

        let task = try store.addTask(title: "Задача")
        try store.setPlannedDate("2026-10-20", for: task.id)
        try store.setPlannedInterval(plannedTime: "08:00", durationMinutes: 60, for: task.id)

        #expect(throws: TaskTimeIntervalError.incompletePair(time: "08:30", durationMinutes: nil)) {
            try store.setPlannedInterval(plannedTime: "08:30", durationMinutes: nil, for: task.id)
        }
        #expect(throws: TaskTimeIntervalError.incompletePair(time: nil, durationMinutes: 45)) {
            try store.setPlannedInterval(plannedTime: nil, durationMinutes: 45, for: task.id)
        }
        let stored = try store.tasks()
        #expect(stored.first?.plannedTime == "08:00")
        #expect(stored.first?.durationMinutes == 60)
    }

    @Test("invalid time or duration values are rejected and keep the old pair")
    @MainActor
    func invalidValuesRejected() throws {
        let dir = try TempDir.make()
        defer { TempDir.remove(dir) }
        let store = try OrbitTaskStore(storeURL: dir.appendingPathComponent("Orbit.store"))

        let task = try store.addTask(title: "Задача")
        try store.setPlannedDate("2026-10-20", for: task.id)
        try store.setPlannedInterval(plannedTime: "07:00", durationMinutes: 30, for: task.id)

        #expect(throws: TaskTimeIntervalError.invalidTime("24:00")) {
            try store.setPlannedInterval(plannedTime: "24:00", durationMinutes: 30, for: task.id)
        }
        #expect(throws: TaskTimeIntervalError.invalidTime("9:00")) {
            try store.setPlannedInterval(plannedTime: "9:00", durationMinutes: 30, for: task.id)
        }
        #expect(throws: TaskTimeIntervalError.invalidDuration(0)) {
            try store.setPlannedInterval(plannedTime: "07:30", durationMinutes: 0, for: task.id)
        }
        #expect(throws: TaskTimeIntervalError.invalidDuration(1441)) {
            try store.setPlannedInterval(plannedTime: "07:30", durationMinutes: 1441, for: task.id)
        }
        #expect(throws: TaskTimeIntervalError.invalidDuration(Int.max)) {
            try store.setPlannedInterval(plannedTime: "07:30", durationMinutes: Int.max, for: task.id)
        }
        let stored = try store.tasks()
        #expect(stored.first?.plannedTime == "07:00")
        #expect(stored.first?.durationMinutes == 30)
    }

    @Test("NATIVE-MIN5: new writes below 5 minutes are rejected before mutation and keep the stored pair")
    @MainActor
    func writeMinimumRejectsBelowFive() throws {
        let dir = try TempDir.make()
        defer { TempDir.remove(dir) }
        let store = try OrbitTaskStore(storeURL: dir.appendingPathComponent("Orbit.store"))

        let task = try store.addTask(title: "Задача")
        try store.setPlannedDate("2026-10-20", for: task.id)
        try store.setPlannedInterval(plannedTime: "07:00", durationMinutes: 30, for: task.id)

        for low in [1, 2, 3, 4] {
            #expect(throws: TaskTimeIntervalError.invalidDuration(low)) {
                try store.setPlannedInterval(plannedTime: "07:30", durationMinutes: low, for: task.id)
            }
        }
        #expect(throws: TaskTimeIntervalError.invalidDuration(0)) {
            try store.setPlannedInterval(plannedTime: "07:30", durationMinutes: 0, for: task.id)
        }

        // Every rejection happened before any mutation: the stored pair and
        // the disk state are unchanged.
        var stored = try store.tasks()
        #expect(stored.first?.plannedTime == "07:00")
        #expect(stored.first?.durationMinutes == 30)
        let reopened = try OrbitTaskStore(storeURL: dir.appendingPathComponent("Orbit.store"))
        #expect(try reopened.tasks().first?.durationMinutes == 30)

        // The minimum is not a multiple-of-5 step: 5, 6 and 7 are accepted.
        try store.setPlannedInterval(plannedTime: "08:00", durationMinutes: 5, for: task.id)
        try store.setPlannedInterval(plannedTime: "09:00", durationMinutes: 6, for: task.id)
        try store.setPlannedInterval(plannedTime: "09:30", durationMinutes: 7, for: task.id)
        stored = try store.tasks()
        #expect(stored.first?.plannedTime == "09:30")
        #expect(stored.first?.durationMinutes == 7)

        // Clear remains a normal operation.
        try store.setPlannedInterval(plannedTime: nil, durationMinutes: nil, for: task.id)
        stored = try store.tasks()
        #expect(stored.first?.plannedTime == nil)
        #expect(stored.first?.durationMinutes == nil)
        #expect(stored.first?.plannedDate == "2026-10-20")
    }

    @Test("NATIVE-MIN5: legacy stored 1...4 stay readable after reopen; new writes stay gated")
    @MainActor
    func legacyShortDurationsRemainReadable() throws {
        let dir = try TempDir.make()
        defer { TempDir.remove(dir) }
        let url = dir.appendingPathComponent("Orbit.store")

        // Legacy rows are created through the SwiftData model in this
        // isolated test context — no store-API bypass was added for the app.
        let legacyOneID = UUID()
        let legacyFourID = UUID()
        let config = ModelConfiguration(url: url, cloudKitDatabase: .none)
        let container = try ModelContainer(for: OrbitTask.self, configurations: config)
        let context = ModelContext(container)
        context.insert(OrbitTask(
            id: legacyOneID,
            title: "Легаси 1 минута",
            createdAt: Date(timeIntervalSince1970: 0),
            plannedDate: "2026-10-20",
            plannedTime: "09:00",
            durationMinutes: 1
        ))
        context.insert(OrbitTask(
            id: legacyFourID,
            title: "Легаси 4 минуты",
            createdAt: Date(timeIntervalSince1970: 1),
            plannedDate: "2026-10-20",
            plannedTime: "10:00",
            durationMinutes: 4
        ))
        try context.save()

        // Reopen with the current core: short values survive on disk.
        let store = try OrbitTaskStore(storeURL: url)
        let tasks = try store.tasks()
        #expect(tasks.count == 2)
        let one = try #require(tasks.first { $0.id == legacyOneID })
        #expect(one.plannedDate == "2026-10-20")
        #expect(one.plannedTime == "09:00")
        #expect(one.durationMinutes == 1)
        let four = try #require(tasks.first { $0.id == legacyFourID })
        #expect(four.plannedTime == "10:00")
        #expect(four.durationMinutes == 4)

        // Read end and positive projection segments for the legacy rows.
        #expect(TaskTimeInterval.end(plannedDate: "2026-10-20", plannedTime: "09:00", durationMinutes: 1)?.time == "09:01")
        let projection = TaskDayProjector.project(day: "2026-10-20", in: tasks)
        #expect(projection.timedSegments.count == 2)
        #expect(projection.timedSegments.allSatisfy { $0.endMinute > $0.startMinute })

        // A new write on the legacy row is gated and changes nothing.
        #expect(throws: TaskTimeIntervalError.invalidDuration(3)) {
            try store.setPlannedInterval(plannedTime: "09:30", durationMinutes: 3, for: legacyOneID)
        }

        // Legacy date move and completion keep the short interval untouched.
        try store.setPlannedDate("2026-10-21", for: legacyOneID)
        try store.setCompleted(true, for: legacyOneID)
        var stored = try store.tasks()
        let moved = try #require(stored.first { $0.id == legacyOneID })
        #expect(moved.plannedDate == "2026-10-21")
        #expect(moved.plannedTime == "09:00")
        #expect(moved.durationMinutes == 1)
        #expect(moved.isCompleted)

        // Legacy clear still works through the normal path.
        try store.setPlannedInterval(plannedTime: nil, durationMinutes: nil, for: legacyOneID)
        stored = try store.tasks()
        let cleared = try #require(stored.first { $0.id == legacyOneID })
        #expect(cleared.plannedTime == nil)
        #expect(cleared.durationMinutes == nil)
    }

    @Test("interval without a planned date is rejected; undated clear is allowed")
    @MainActor
    func intervalRequiresDate() throws {
        let dir = try TempDir.make()
        defer { TempDir.remove(dir) }
        let store = try OrbitTaskStore(storeURL: dir.appendingPathComponent("Orbit.store"))

        let task = try store.addTask(title: "Без даты")
        #expect(throws: TaskTimeIntervalError.missingDate) {
            try store.setPlannedInterval(plannedTime: "10:00", durationMinutes: 30, for: task.id)
        }
        let stored = try store.tasks()
        #expect(stored.first?.plannedTime == nil)
        #expect(stored.first?.durationMinutes == nil)

        // Clearing an absent interval on an undated task is a safe no-op.
        try store.setPlannedInterval(plannedTime: nil, durationMinutes: nil, for: task.id)
        #expect(try store.tasks().first?.plannedTime == nil)
    }

    @Test("clearing the date clears the pair in the same save; date change preserves it")
    @MainActor
    func dateInterplay() throws {
        let dir = try TempDir.make()
        defer { TempDir.remove(dir) }
        let store = try OrbitTaskStore(storeURL: dir.appendingPathComponent("Orbit.store"))

        let task = try store.addTask(title: "С датой и интервалом")
        try store.setPlannedDate("2026-10-20", for: task.id)
        try store.setPlannedInterval(plannedTime: "22:30", durationMinutes: 120, for: task.id)

        // Moving the date keeps the valid interval.
        try store.setPlannedDate("2026-10-21", for: task.id)
        var stored = try store.tasks()
        #expect(stored.first?.plannedDate == "2026-10-21")
        #expect(stored.first?.plannedTime == "22:30")
        #expect(stored.first?.durationMinutes == 120)

        // Clearing the date wipes the interval too.
        try store.setPlannedDate(nil, for: task.id)
        stored = try store.tasks()
        #expect(stored.first?.plannedDate == nil)
        #expect(stored.first?.plannedTime == nil)
        #expect(stored.first?.durationMinutes == nil)
    }

    @Test("date move that pushes the derived end out of range is rejected atomically")
    @MainActor
    func dateMoveEndOutOfRange() throws {
        let dir = try TempDir.make()
        defer { TempDir.remove(dir) }
        let store = try OrbitTaskStore(storeURL: dir.appendingPathComponent("Orbit.store"))

        let task = try store.addTask(title: "Граничная задача")
        try store.setPlannedDate("2199-12-30", for: task.id)
        try store.setPlannedInterval(plannedTime: "23:30", durationMinutes: 60, for: task.id)

        // 2199-12-31 23:30 + 60 → 2200-01-01 00:30 → outside the product range.
        #expect(throws: TaskTimeIntervalError.endOutOfRange) {
            try store.setPlannedDate("2199-12-31", for: task.id)
        }
        let stored = try store.tasks()
        #expect(stored.first?.plannedDate == "2199-12-30")
        #expect(stored.first?.plannedTime == "23:30")
        #expect(stored.first?.durationMinutes == 60)
    }

    @Test("interval end crossing midnight is accepted by the store")
    @MainActor
    func midnightIntervalAccepted() throws {
        let dir = try TempDir.make()
        defer { TempDir.remove(dir) }
        let store = try OrbitTaskStore(storeURL: dir.appendingPathComponent("Orbit.store"))

        let task = try store.addTask(title: "Ночная задача")
        try store.setPlannedDate("2026-10-13", for: task.id)
        try store.setPlannedInterval(plannedTime: "23:30", durationMinutes: 90, for: task.id)
        let stored = try store.tasks()
        #expect(stored.first?.plannedTime == "23:30")
        #expect(stored.first?.durationMinutes == 90)
    }

    @Test("setPlannedInterval for unknown id throws taskNotFound")
    @MainActor
    func intervalUnknownId() throws {
        let dir = try TempDir.make()
        defer { TempDir.remove(dir) }
        let store = try OrbitTaskStore(storeURL: dir.appendingPathComponent("Orbit.store"))

        let missingId = UUID()
        #expect(throws: OrbitStoreError.taskNotFound(id: missingId)) {
            try store.setPlannedInterval(plannedTime: "10:00", durationMinutes: 30, for: missingId)
        }
    }

    @Test("disk reopen keeps the time interval with the date")
    @MainActor
    func intervalDiskReopen() throws {
        let dir = try TempDir.make()
        defer { TempDir.remove(dir) }
        let storeURL = dir.appendingPathComponent("Orbit.store")

        var firstStore: OrbitTaskStore? = try OrbitTaskStore(storeURL: storeURL)
        let task = try firstStore?.addTask(title: "Интервал на диске", now: Date(timeIntervalSince1970: 1_760_000_000))
        try firstStore?.setPlannedDate("2026-10-21", for: task?.id ?? UUID())
        try firstStore?.setPlannedInterval(plannedTime: "23:30", durationMinutes: 90, for: task?.id ?? UUID())
        firstStore = nil

        let reopened = try OrbitTaskStore(storeURL: storeURL)
        let all = try reopened.tasks()
        #expect(all.count == 1)
        #expect(all.first?.plannedDate == "2026-10-21")
        #expect(all.first?.plannedTime == "23:30")
        #expect(all.first?.durationMinutes == 90)
    }
}
