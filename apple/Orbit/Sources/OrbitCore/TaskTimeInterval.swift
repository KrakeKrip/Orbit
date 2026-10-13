import Foundation

/// Rejected before any mutation when a time-interval candidate does not
/// satisfy the pair/date/end contract (own type, mirroring `TaskTitleError`).
public enum TaskTimeIntervalError: Error, Equatable {
    /// Exactly one of time/duration is set; both nil or both set is required.
    case incompletePair(time: String?, durationMinutes: Int?)
    case invalidTime(String)
    case invalidDuration(Int)
    /// A non-nil interval was requested for a task without a planned date.
    case missingDate
    /// The derived end lands outside the Gregorian 1900–2199 product range.
    case endOutOfRange
}

/// Pure civil wall-clock contract for a task's time interval:
/// `plannedTime` strict ASCII `HH:mm` (00:00..23:59) plus `durationMinutes`
/// 1...1440, always as a complete pair on a dated task. Everything here is
/// deterministic integer civil arithmetic — no `Calendar`, `TimeZone`, DST or
/// locale input; the derived end is never stored.
public enum TaskTimeInterval {
    public static let minimumDurationMinutes = 1
    public static let maximumDurationMinutes = 1440

    /// Strict ASCII `HH:mm`, 00:00..23:59; 24:00 is not a valid start.
    public static func isValidTime(_ value: String) -> Bool {
        let characters = Array(value)
        guard characters.count == 5, characters[2] == ":" else { return false }
        let digits = Set("0123456789")
        for index in [0, 1, 3, 4] where !digits.contains(characters[index]) {
            return false
        }
        let hour = Int(String(characters[0...1])) ?? 24
        let minute = Int(String(characters[3...4])) ?? 60
        return hour < 24 && minute < 60
    }

    /// Whole minutes, 1...1440; bounds are checked before any arithmetic, so
    /// extreme inputs (e.g. Int.max) never reach the end calculation.
    public static func isValidDuration(_ value: Int) -> Bool {
        (minimumDurationMinutes...maximumDurationMinutes).contains(value)
    }

    /// The interval is either fully absent (nil/nil) or fully present.
    public static func isCompletePair(time: String?, durationMinutes: Int?) -> Bool {
        (time == nil) == (durationMinutes == nil)
    }

    /// Derived end of the interval as civil wall-clock `(date, time)` strings.
    /// The end may cross midnight (at most one day for the 1...1440 range);
    /// exact midnight lands at 00:00 of the next date. Returns nil when any
    /// input is invalid or the end falls outside the Gregorian 1900–2199
    /// product range. The end is a computed value, never stored.
    public static func end(
        plannedDate: String,
        plannedTime: String,
        durationMinutes: Int
    ) -> (date: String, time: String)? {
        guard TaskPlannedDate.isValid(plannedDate),
            isValidTime(plannedTime),
            isValidDuration(durationMinutes)
        else { return nil }

        let startDay = daysFromCivil(plannedDate)
        let startMinutes = plannedMinutes(plannedTime)
        let totalMinutes = startMinutes + durationMinutes
        let endDay = startDay + totalMinutes / 1440
        let endClock = totalMinutes % 1440

        let civil = civilFromDays(endDay)
        guard TaskPlannedDate.isValid(civil.isoDate) else { return nil }
        return (civil.isoDate, clockString(endClock))
    }

    // MARK: - Civil arithmetic (proleptic Gregorian, integer-only)

    private static func plannedMinutes(_ time: String) -> Int {
        let characters = Array(time)
        return (Int(String(characters[0...1])) ?? 0) * 60 + (Int(String(characters[3...4])) ?? 0)
    }

    private static func clockString(_ totalMinutes: Int) -> String {
        String(format: "%02d:%02d", totalMinutes / 60, totalMinutes % 60)
    }

    /// Days since 1970-01-01 for a validated `YYYY-MM-DD` string
    /// (Howard Hinnant's civil-from-days algorithm, integer-only).
    private static func daysFromCivil(_ isoDate: String) -> Int {
        let year = Int(isoDate.prefix(4)) ?? 1900
        let month = Int(isoDate.dropFirst(5).prefix(2)) ?? 1
        let day = Int(isoDate.suffix(2)) ?? 1
        let shiftedYear = year - (month <= 2 ? 1 : 0)
        let era = shiftedYear / 400
        let yearOfEra = shiftedYear - era * 400
        let dayOfYear = (153 * (month + (month > 2 ? -3 : 9)) + 2) / 5 + day - 1
        let dayOfEra = yearOfEra * 365 + yearOfEra / 4 - yearOfEra / 100 + dayOfYear
        return era * 146_097 + dayOfEra - 719_468
    }

    /// Inverse of `daysFromCivil`.
    private static func civilFromDays(_ days: Int) -> (isoDate: String, year: Int, month: Int, day: Int) {
        let shifted = days + 719_468
        let era = (shifted >= 0 ? shifted : shifted - 146_096) / 146_097
        let dayOfEra = shifted - era * 146_097
        let yearOfEra = (dayOfEra - dayOfEra / 1_460 + dayOfEra / 36_524 - dayOfEra / 146_096) / 365
        let year = yearOfEra + era * 400
        let dayOfYear = dayOfEra - (365 * yearOfEra + yearOfEra / 4 - yearOfEra / 100)
        let monthIndex = (5 * dayOfYear + 2) / 153
        let day = dayOfYear - (153 * monthIndex + 2) / 5 + 1
        let month = monthIndex + (monthIndex < 10 ? 3 : -9)
        let fullYear = year + (month <= 2 ? 1 : 0)
        let isoDate = String(format: "%04d-%02d-%02d", fullYear, month, day)
        return (isoDate, fullYear, month, day)
    }
}
