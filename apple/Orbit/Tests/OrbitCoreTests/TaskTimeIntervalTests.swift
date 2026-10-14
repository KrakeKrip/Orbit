import Foundation
import Testing
import OrbitCore

@Suite("TaskTimeInterval contract")
struct TaskTimeIntervalTests {

    @Test("valid times and durations pass")
    func validValues() {
        #expect(TaskTimeInterval.isValidTime("00:00"))
        #expect(TaskTimeInterval.isValidTime("09:05"))
        #expect(TaskTimeInterval.isValidTime("23:59"))
        #expect(TaskTimeInterval.isValidDuration(1))
        #expect(TaskTimeInterval.isValidDuration(90))
        #expect(TaskTimeInterval.isValidDuration(1440))
        #expect(TaskTimeInterval.isCompletePair(time: nil, durationMinutes: nil))
        #expect(TaskTimeInterval.isCompletePair(time: "10:00", durationMinutes: 30))
    }

    @Test("invalid clock format is rejected: 24:00, minutes, widths, separators, non-ASCII")
    func invalidTimes() {
        #expect(!TaskTimeInterval.isValidTime("24:00"))
        #expect(!TaskTimeInterval.isValidTime("23:60"))
        #expect(!TaskTimeInterval.isValidTime("9:00"))
        #expect(!TaskTimeInterval.isValidTime("09:5"))
        #expect(!TaskTimeInterval.isValidTime("0900"))
        #expect(!TaskTimeInterval.isValidTime("09-00"))
        #expect(!TaskTimeInterval.isValidTime("09:00:30"))
        #expect(!TaskTimeInterval.isValidTime(" 09:00"))
        #expect(!TaskTimeInterval.isValidTime("09:00 "))
        #expect(!TaskTimeInterval.isValidTime("０９:００"))
        #expect(!TaskTimeInterval.isValidTime(""))
    }

    @Test("duration bounds reject 0, negatives, over 1440 and extremes before arithmetic")
    func invalidDurations() {
        #expect(!TaskTimeInterval.isValidDuration(0))
        #expect(!TaskTimeInterval.isValidDuration(-1))
        #expect(!TaskTimeInterval.isValidDuration(1441))
        #expect(!TaskTimeInterval.isValidDuration(Int.max))
        #expect(!TaskTimeInterval.isValidDuration(Int.min))
        #expect(!TaskTimeInterval.isCompletePair(time: "10:00", durationMinutes: nil))
        #expect(!TaskTimeInterval.isCompletePair(time: nil, durationMinutes: 30))
    }

    @Test("write gate NATIVE-MIN5: 5...1440 writable including 5/6/7; read compatibility keeps 1...4")
    func writableDurationGate() {
        #expect(TaskTimeInterval.isWritableDuration(5))
        #expect(TaskTimeInterval.isWritableDuration(6))
        #expect(TaskTimeInterval.isWritableDuration(7))
        #expect(TaskTimeInterval.isWritableDuration(30))
        #expect(TaskTimeInterval.isWritableDuration(1440))
        #expect(!TaskTimeInterval.isWritableDuration(1))
        #expect(!TaskTimeInterval.isWritableDuration(4))
        #expect(!TaskTimeInterval.isWritableDuration(0))
        #expect(!TaskTimeInterval.isWritableDuration(-5))
        #expect(!TaskTimeInterval.isWritableDuration(1441))
        #expect(!TaskTimeInterval.isWritableDuration(Int.max))
        // The read rule is not weakened: legacy 1...4 stay valid reads and
        // keep deriving an end.
        #expect(TaskTimeInterval.isValidDuration(1))
        #expect(TaskTimeInterval.isValidDuration(4))
        #expect(TaskTimeInterval.end(plannedDate: "2026-10-13", plannedTime: "10:00", durationMinutes: 1)?.time == "10:01")
    }

    @Test("end inside the same day")
    func endSameDay() {
        let end = TaskTimeInterval.end(plannedDate: "2026-10-13", plannedTime: "10:00", durationMinutes: 90)
        #expect(end?.date == "2026-10-13")
        #expect(end?.time == "11:30")
    }

    @Test("end crosses midnight; exact midnight lands at 00:00 of the next date")
    func endCrossesMidnight() {
        let crossed = TaskTimeInterval.end(plannedDate: "2026-10-13", plannedTime: "23:30", durationMinutes: 90)
        #expect(crossed?.date == "2026-10-14")
        #expect(crossed?.time == "01:00")

        let exactMidnight = TaskTimeInterval.end(plannedDate: "2026-10-13", plannedTime: "00:00", durationMinutes: 1440)
        #expect(exactMidnight?.date == "2026-10-14")
        #expect(exactMidnight?.time == "00:00")
    }

    @Test("end handles month and leap boundaries")
    func endBoundaryDays() {
        let monthEnd = TaskTimeInterval.end(plannedDate: "2026-10-31", plannedTime: "23:00", durationMinutes: 120)
        #expect(monthEnd?.date == "2026-11-01")
        #expect(monthEnd?.time == "01:00")

        let leapDay = TaskTimeInterval.end(plannedDate: "2024-02-28", plannedTime: "12:00", durationMinutes: 1440)
        #expect(leapDay?.date == "2024-02-29")
        #expect(leapDay?.time == "12:00")

        let commonYear = TaskTimeInterval.end(plannedDate: "2025-02-28", plannedTime: "12:00", durationMinutes: 1440)
        #expect(commonYear?.date == "2025-03-01")
    }

    @Test("end outside 1900–2199 returns nil; lower boundary works")
    func endRangeBounds() {
        // 2199-12-31 23:59 + 1 minute = 2200-01-01 00:00 → outside.
        #expect(TaskTimeInterval.end(plannedDate: "2199-12-31", plannedTime: "23:59", durationMinutes: 1) == nil)
        // Last fitting minute of the range.
        let lastFitting = TaskTimeInterval.end(plannedDate: "2199-12-31", plannedTime: "23:58", durationMinutes: 1)
        #expect(lastFitting?.date == "2199-12-31")
        #expect(lastFitting?.time == "23:59")
        // Earliest date with a zero-day carry works.
        let earliest = TaskTimeInterval.end(plannedDate: "1900-01-01", plannedTime: "00:00", durationMinutes: 30)
        #expect(earliest?.date == "1900-01-01")
        #expect(earliest?.time == "00:30")
    }

    @Test("end returns nil for invalid inputs")
    func endInvalidInputs() {
        #expect(TaskTimeInterval.end(plannedDate: "2026-13-01", plannedTime: "10:00", durationMinutes: 30) == nil)
        #expect(TaskTimeInterval.end(plannedDate: "2026-10-13", plannedTime: "24:00", durationMinutes: 30) == nil)
        #expect(TaskTimeInterval.end(plannedDate: "2026-10-13", plannedTime: "10:00", durationMinutes: 1441) == nil)
    }

    @Test("civil result is calendar- and timezone-independent (Gregorian literals)")
    func civilResultIndependentOfSystemCalendar() {
        // The end calculation takes no Calendar/TimeZone input at all; under a
        // Buddhist system calendar the civil result stays Gregorian.
        var buddhist = Calendar(identifier: .buddhist)
        buddhist.timeZone = TimeZone(identifier: "Asia/Bangkok") ?? .current
        var islamic = Calendar(identifier: .islamicCivil)
        islamic.timeZone = TimeZone(identifier: "America/New_York") ?? .current

        let start = "2026-10-13"
        #expect(TaskPlannedDate.isValid(start))
        let end = TaskTimeInterval.end(plannedDate: start, plannedTime: "23:30", durationMinutes: 90)
        #expect(end?.date == "2026-10-14")
        #expect(end?.time == "01:00")
        // The derived end date satisfies the Gregorian storage contract.
        #expect(TaskPlannedDate.isValid(end?.date ?? ""))
        // Calendars participate in no arithmetic; they only pre-validate the start.
        #expect(TaskPlannedDate.civilDateString(from: TaskPlannedDate.date(fromCivilDateString: start, calendar: buddhist)!, calendar: buddhist) == start)
        #expect(TaskPlannedDate.civilDateString(from: TaskPlannedDate.date(fromCivilDateString: start, calendar: islamic)!, calendar: islamic) == start)
    }
}
