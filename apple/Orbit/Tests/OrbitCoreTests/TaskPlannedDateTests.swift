import Foundation
import Testing
import OrbitCore

@Suite("TaskPlannedDate contract")
struct TaskPlannedDateTests {

    @Test("valid dates pass and are returned unchanged")
    func validDates() {
        #expect(TaskPlannedDate.validated("2026-10-20") == "2026-10-20")
        #expect(TaskPlannedDate.validated("1900-01-01") == "1900-01-01")
        #expect(TaskPlannedDate.validated("2199-12-31") == "2199-12-31")
        #expect(TaskPlannedDate.validated("2000-02-29") == "2000-02-29") // leap century
        #expect(TaskPlannedDate.validated("2024-02-29") == "2024-02-29")
        #expect(TaskPlannedDate.validated(nil) == nil)
    }

    @Test("invalid format is rejected")
    func invalidFormat() {
        #expect(TaskPlannedDate.validated("20261020") == nil)
        #expect(TaskPlannedDate.validated("2026-10-2") == nil)
        #expect(TaskPlannedDate.validated("2026-1-02") == nil)
        #expect(TaskPlannedDate.validated("26-10-20") == nil)
        #expect(TaskPlannedDate.validated("2026/10/20") == nil)
        #expect(TaskPlannedDate.validated("2026-10-20T00:00") == nil)
        #expect(TaskPlannedDate.validated(" 2026-10-20") == nil)
        #expect(TaskPlannedDate.validated("2026-10-20 ") == nil)
        #expect(TaskPlannedDate.validated("") == nil)
        #expect(TaskPlannedDate.validated("２０２６-１０-２０") == nil) // non-ASCII digits
    }

    @Test("impossible month/day and leap rules are rejected")
    func invalidCalendarDays() {
        #expect(TaskPlannedDate.validated("2026-13-01") == nil)
        #expect(TaskPlannedDate.validated("2026-00-10") == nil)
        #expect(TaskPlannedDate.validated("2026-04-31") == nil)
        #expect(TaskPlannedDate.validated("2026-02-29") == nil) // common year
        #expect(TaskPlannedDate.validated("1900-02-29") == nil) // 1900 is not a leap year
        #expect(TaskPlannedDate.validated("2100-02-29") == nil) // 2100 is not a leap year
        #expect(TaskPlannedDate.validated("2026-02-30") == nil)
        #expect(TaskPlannedDate.validated("2026-00-00") == nil)
    }

    @Test("calendar range 1900–2199 is enforced")
    func rangeBounds() {
        #expect(TaskPlannedDate.validated("1899-12-31") == nil)
        #expect(TaskPlannedDate.validated("2200-01-01") == nil)
        #expect(TaskPlannedDate.validated("1900-02-28") == "1900-02-28")
        #expect(TaskPlannedDate.validated("2199-01-31") == "2199-01-31")
    }

    @Test("picker adapter roundtrip keeps the same civil day")
    func adapterRoundtrip() {
        var moscow = Calendar(identifier: .gregorian)
        moscow.timeZone = TimeZone(identifier: "Europe/Moscow") ?? .current

        let value = "2026-10-20"
        let date = TaskPlannedDate.date(fromCivilDateString: value, calendar: moscow)
        #expect(date != nil)
        #expect(TaskPlannedDate.civilDateString(from: date!, calendar: moscow) == value)

        // The civil day comes from the adapter calendar, not from a UTC instant:
        // 2026-01-01T00:00:00Z is already 2026-01-01 in Moscow (UTC+3)
        // but still 2025-12-31 in New York (UTC-5).
        var newYork = Calendar(identifier: .gregorian)
        newYork.timeZone = TimeZone(identifier: "America/New_York") ?? .current
        let midnightUTC = Date(timeIntervalSince1970: 1_767_225_600)
        #expect(TaskPlannedDate.civilDateString(from: midnightUTC, calendar: moscow) == "2026-01-01")
        #expect(TaskPlannedDate.civilDateString(from: midnightUTC, calendar: newYork) == "2025-12-31")

        // Adapter rejects invalid values instead of shifting them.
        #expect(TaskPlannedDate.date(fromCivilDateString: "2026-02-30", calendar: moscow) == nil)
    }
}
