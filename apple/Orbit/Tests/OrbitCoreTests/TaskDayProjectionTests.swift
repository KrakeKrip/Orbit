import Foundation
import Testing
import OrbitCore

@Suite("TaskDayProjection contract")
struct TaskDayProjectionTests {

    @MainActor
    private func makeTask(
        _ title: String,
        date: String?,
        time: String? = nil,
        duration: Int? = nil,
        completed: Bool = false
    ) -> OrbitTask {
        let task = OrbitTask(title: title, createdAt: Date(timeIntervalSince1970: 1_760_000_000))
        if let date { task.setPlannedDate(date) }
        task.setPlannedInterval(plannedTime: time, durationMinutes: duration)
        if completed { task.complete(at: Date(timeIntervalSince1970: 1_760_000_100)) }
        return task
    }

    @Test("same-day interval projects minutes; untimed listed separately")
    @MainActor
    func sameDayAndUntimed() {
        let untimed = makeTask("Без времени", date: "2026-10-13")
        let timed = makeTask("С временем", date: "2026-10-13", time: "09:00", duration: 30)
        let projection = TaskDayProjector.project(day: "2026-10-13", in: [untimed, timed])

        #expect(projection.day == "2026-10-13")
        #expect(projection.untimedTaskIDs == [untimed.id])
        #expect(projection.timedSegments.count == 1)
        let segment = projection.timedSegments[0]
        #expect(segment.taskID == timed.id)
        #expect(segment.day == "2026-10-13")
        #expect(segment.startMinute == 540)
        #expect(segment.endMinute == 570)
        #expect(segment.continuesFromPreviousDay == false)
        #expect(segment.continuesIntoNextDay == false)
    }

    @Test("untimed requires the selected day; other-day and undated excluded")
    @MainActor
    func untimedDayFilter() {
        let bank = makeTask("Банк", date: "2026-10-13")
        let yesterday = makeTask("Вчера", date: "2026-10-12")
        let undated = makeTask("Без даты", date: nil)
        let projection = TaskDayProjector.project(day: "2026-10-13", in: [bank, yesterday, undated])
        #expect(projection.untimedTaskIDs == [bank.id])
        #expect(projection.timedSegments.isEmpty)
    }

    @Test("overnight interval projects both days with continuation flags")
    @MainActor
    func overnightBothDays() {
        let task = makeTask("Ночная задача", date: "2026-10-13", time: "23:30", duration: 90)
        let day13 = TaskDayProjector.project(day: "2026-10-13", in: [task])
        #expect(day13.timedSegments.count == 1)
        #expect(day13.timedSegments[0].startMinute == 1410)
        #expect(day13.timedSegments[0].endMinute == 1440)
        #expect(day13.timedSegments[0].continuesIntoNextDay == true)
        #expect(day13.timedSegments[0].continuesFromPreviousDay == false)

        let day14 = TaskDayProjector.project(day: "2026-10-14", in: [task])
        #expect(day14.timedSegments.count == 1)
        #expect(day14.timedSegments[0].startMinute == 0)
        #expect(day14.timedSegments[0].endMinute == 60)
        #expect(day14.timedSegments[0].continuesFromPreviousDay == true)
        #expect(day14.timedSegments[0].continuesIntoNextDay == false)

        // Unrelated days carry no segment for this task.
        #expect(TaskDayProjector.project(day: "2026-10-15", in: [task]).timedSegments.isEmpty)
        #expect(TaskDayProjector.project(day: "2026-10-12", in: [task]).timedSegments.isEmpty)
    }

    @Test("exact midnight end: positive part on start day, no zero-length segment next day")
    @MainActor
    func exactMidnight() {
        let task = makeTask("До полуночи плюс", date: "2026-10-13", time: "23:30", duration: 30)
        let day13 = TaskDayProjector.project(day: "2026-10-13", in: [task])
        #expect(day13.timedSegments.count == 1)
        #expect(day13.timedSegments[0].startMinute == 1410)
        #expect(day13.timedSegments[0].endMinute == 1440)
        #expect(day13.timedSegments[0].continuesIntoNextDay == true)

        let day14 = TaskDayProjector.project(day: "2026-10-14", in: [task])
        #expect(day14.timedSegments.isEmpty)
    }

    @Test("full-day duration: start 00:00 gives one full segment; start 09:00 splits across days")
    @MainActor
    func fullDayDuration() {
        let fromMidnight = makeTask("Сутки с полуночи", date: "2026-10-13", time: "00:00", duration: 1440)
        let startDay = TaskDayProjector.project(day: "2026-10-13", in: [fromMidnight])
        #expect(startDay.timedSegments.count == 1)
        #expect(startDay.timedSegments[0].startMinute == 0)
        #expect(startDay.timedSegments[0].endMinute == 1440)
        #expect(TaskDayProjector.project(day: "2026-10-14", in: [fromMidnight]).timedSegments.isEmpty)

        let fromMorning = makeTask("Сутки с утра", date: "2026-10-13", time: "09:00", duration: 1440)
        let day13 = TaskDayProjector.project(day: "2026-10-13", in: [fromMorning])
        #expect(day13.timedSegments.count == 1)
        #expect(day13.timedSegments[0].startMinute == 540)
        #expect(day13.timedSegments[0].endMinute == 1440)
        #expect(day13.timedSegments[0].continuesIntoNextDay == true)
        let day14 = TaskDayProjector.project(day: "2026-10-14", in: [fromMorning])
        #expect(day14.timedSegments.count == 1)
        #expect(day14.timedSegments[0].startMinute == 0)
        #expect(day14.timedSegments[0].endMinute == 540)
        #expect(day14.timedSegments[0].continuesFromPreviousDay == true)
    }

    @Test("completed tasks stay in the projection")
    @MainActor
    func completedIncluded() {
        let done = makeTask("Сделано", date: "2026-10-13", time: "10:00", duration: 30, completed: true)
        let projection = TaskDayProjector.project(day: "2026-10-13", in: [done])
        #expect(projection.timedSegments.count == 1)
        #expect(projection.untimedTaskIDs.isEmpty)
    }

    @Test("invalid day, partial pairs and bad values are excluded, not repaired")
    @MainActor
    func invalidInputsExcluded() {
        let partial = makeTask("Только время", date: "2026-10-13", time: "10:00")
        let badTime = makeTask("Плохое время", date: "2026-10-13", time: "24:00", duration: 30)
        let badDuration = makeTask("Плохая длительность", date: "2026-10-13", time: "10:00", duration: 0)
        let hugeDuration = makeTask("Огромная длительность", date: "2026-10-13", time: "10:00", duration: Int.max)
        let projection = TaskDayProjector.project(day: "2026-10-13", in: [partial, badTime, badDuration, hugeDuration])
        #expect(projection.timedSegments.isEmpty)
        #expect(projection.untimedTaskIDs.isEmpty)

        // Invalid selected days: empty result without crash.
        for day in [nil, "2026-13-01", "not-a-date", ""] {
            let empty = TaskDayProjector.project(day: day, in: [partial])
            #expect(empty.timedSegments.isEmpty)
            #expect(empty.untimedTaskIDs.isEmpty)
        }
    }

    @Test("range boundary: end outside 1900–2199 excludes the interval without clipping")
    @MainActor
    func rangeEndRejected() {
        let over = makeTask("За пределом", date: "2199-12-31", time: "23:59", duration: 1)
        let projection = TaskDayProjector.project(day: "2199-12-31", in: [over])
        #expect(projection.timedSegments.isEmpty)

        let lastFitting = makeTask("Последняя", date: "2199-12-31", time: "23:58", duration: 1)
        let fitting = TaskDayProjector.project(day: "2199-12-31", in: [lastFitting])
        #expect(fitting.timedSegments.count == 1)
        #expect(fitting.timedSegments[0].endMinute == 1439)
    }

    @Test("overlapping tasks keep separate segments; sort is start/end/uuid stable")
    @MainActor
    func overlapAndSort() {
        let first = makeTask("Первая", date: "2026-10-13", time: "09:00", duration: 60)
        let second = makeTask("Вторая", date: "2026-10-13", time: "09:30", duration: 60)
        let early = makeTask("Ранняя", date: "2026-10-13", time: "09:00", duration: 15)
        let projection = TaskDayProjector.project(day: "2026-10-13", in: [second, early, first])
        #expect(projection.timedSegments.count == 3)
        let minutes = projection.timedSegments.map { [$0.startMinute, $0.endMinute] }
        #expect(minutes == [[540, 555], [540, 600], [570, 630]])
        // Explicit tie check: two segments start at 540; the shorter end first,
        // equal ends would fall back to UUID string order.
        let tie = projection.timedSegments.filter { $0.startMinute == 540 }
        #expect(tie.count == 2)
        let uuidOrdered = tie.map(\.taskID.uuidString)
        #expect(uuidOrdered == uuidOrdered.sorted())
    }

    @Test("repeated reads give stable segments and leave tasks unchanged")
    @MainActor
    func repeatedStableAndUnchanged() {
        let task = makeTask("Стабильность", date: "2026-10-13", time: "23:30", duration: 90)
        let untimed = makeTask("Без времени", date: "2026-10-13")
        let first = TaskDayProjector.project(day: "2026-10-13", in: [task, untimed])
        let second = TaskDayProjector.project(day: "2026-10-13", in: [task, untimed])
        #expect(first == second)
        #expect(first.timedSegments[0].taskID == task.id)
        #expect(first.timedSegments[0].day == "2026-10-13")
        // Input untouched.
        #expect(task.plannedDate == "2026-10-13")
        #expect(task.plannedTime == "23:30")
        #expect(task.durationMinutes == 90)
        #expect(untimed.plannedDate == "2026-10-13")
        #expect(untimed.plannedTime == nil)
    }
}
