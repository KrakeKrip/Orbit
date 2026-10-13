import Foundation
import Testing
import OrbitCore

@Suite("TaskDaySelection contract")
struct TaskDaySelectionTests {

    @MainActor
    private func makeTasks() -> [OrbitTask] {
        let yesterday = OrbitTask(title: "Вчера", createdAt: Date(timeIntervalSince1970: 1_760_000_000))
        yesterday.setPlannedDate("2026-10-12")
        let todayUntimed = OrbitTask(title: "Сегодня без времени", createdAt: Date(timeIntervalSince1970: 1_760_000_005))
        todayUntimed.setPlannedDate("2026-10-13")
        let todayTimed = OrbitTask(title: "Сегодня с временем", createdAt: Date(timeIntervalSince1970: 1_760_000_010))
        todayTimed.setPlannedDate("2026-10-13")
        todayTimed.setPlannedInterval(plannedTime: "09:30", durationMinutes: 45)
        let todayCompleted = OrbitTask(title: "Сегодня завершённая", createdAt: Date(timeIntervalSince1970: 1_760_000_015))
        todayCompleted.setPlannedDate("2026-10-13")
        todayCompleted.complete(at: Date(timeIntervalSince1970: 1_760_000_100))
        let tomorrow = OrbitTask(title: "Завтра", createdAt: Date(timeIntervalSince1970: 1_760_000_020))
        tomorrow.setPlannedDate("2026-10-14")
        let undated = OrbitTask(title: "Без даты", createdAt: Date(timeIntervalSince1970: 1_760_000_025))
        return [yesterday, todayUntimed, todayTimed, todayCompleted, tomorrow, undated]
    }

    @Test("selection keeps exactly today's tasks, timed and untimed, open and completed")
    @MainActor
    func selectsTodaysTasks() {
        let tasks = makeTasks()
        let selected = TaskDaySelection.tasks(onDay: "2026-10-13", in: tasks)
        #expect(selected.map(\.title) == ["Сегодня без времени", "Сегодня с временем", "Сегодня завершённая"])
        #expect(selected.allSatisfy { !$0.isCompleted || $0.title == "Сегодня завершённая" })
        #expect(selected.contains { $0.plannedTime == "09:30" })
        #expect(selected.contains { $0.plannedTime == nil })
    }

    @Test("nil, other dates are excluded")
    @MainActor
    func excludesOthers() {
        let tasks = makeTasks()
        #expect(TaskDaySelection.tasks(onDay: "2026-10-12", in: tasks).map(\.title) == ["Вчера"])
        #expect(TaskDaySelection.tasks(onDay: "2026-10-14", in: tasks).map(\.title) == ["Завтра"])
        #expect(TaskDaySelection.tasks(onDay: "2026-10-13", in: tasks).allSatisfy { $0.title != "Без даты" })
    }

    @Test("completed tasks are not dropped by the helper")
    @MainActor
    func completedKept() {
        let tasks = makeTasks()
        let selected = TaskDaySelection.tasks(onDay: "2026-10-13", in: tasks)
        #expect(selected.contains { $0.isCompleted })
    }

    @Test("same objects, original stable order, no field changes")
    @MainActor
    func identityAndOrderPreserved() {
        let tasks = makeTasks()
        let selected = TaskDaySelection.tasks(onDay: "2026-10-13", in: tasks)
        // Same instances (no copies/new UUIDs).
        #expect(selected.allSatisfy { task in tasks.contains { $0 === task } })
        // Original relative order preserved.
        let indices = selected.map { task in tasks.firstIndex { $0 === task }! }
        #expect(indices == indices.sorted())
        // No mutations.
        let todayTimed = selected.first { $0.title == "Сегодня с временем" }!
        #expect(todayTimed.plannedDate == "2026-10-13")
        #expect(todayTimed.plannedTime == "09:30")
        #expect(todayTimed.durationMinutes == 45)
        #expect(todayTimed.isCompleted == false)
        #expect(tasks.allSatisfy { $0.title != nil })
    }

    @Test("invalid or nil day yields an empty result")
    @MainActor
    func invalidDay() {
        let tasks = makeTasks()
        #expect(TaskDaySelection.tasks(onDay: "2026-13-01", in: tasks).isEmpty)
        #expect(TaskDaySelection.tasks(onDay: "not-a-date", in: tasks).isEmpty)
        #expect(TaskDaySelection.tasks(onDay: nil, in: tasks).isEmpty)
    }

    @Test("currentDay is the local Gregorian civil date of the reference instant")
    func currentDayContract() {
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC") ?? .current
        var moscow = Calendar(identifier: .gregorian)
        moscow.timeZone = TimeZone(identifier: "Europe/Moscow") ?? .current
        var newYork = Calendar(identifier: .gregorian)
        newYork.timeZone = TimeZone(identifier: "America/New_York") ?? .current

        // 2026-01-01T00:00:00Z → 2026-01-01 in Moscow (UTC+3), 2025-12-31 in New York.
        let midnightUTC = Date(timeIntervalSince1970: 1_767_225_600)
        #expect(TaskDaySelection.currentDay(from: midnightUTC, calendar: utc) == "2026-01-01")
        #expect(TaskDaySelection.currentDay(from: midnightUTC, calendar: moscow) == "2026-01-01")
        #expect(TaskDaySelection.currentDay(from: midnightUTC, calendar: newYork) == "2025-12-31")

        // A non-Gregorian system calendar does not change the storage contract.
        var buddhistUTC = Calendar(identifier: .buddhist)
        buddhistUTC.timeZone = TimeZone(identifier: "UTC") ?? .current
        #expect(TaskDaySelection.currentDay(from: midnightUTC, calendar: buddhistUTC) == "2026-01-01")
    }
}
