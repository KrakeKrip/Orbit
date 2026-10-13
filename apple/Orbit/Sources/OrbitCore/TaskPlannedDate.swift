import Foundation

/// Rejected before any mutation when a planned date value does not satisfy
/// the `YYYY-MM-DD` civil contract (own type, mirroring `TaskTitleError`).
public enum TaskPlannedDateError: Error, Equatable {
    case invalid(String)
}

/// Pure civil-date contract for `OrbitTask.plannedDate`:
/// strict `YYYY-MM-DD` Gregorian strings within the product calendar range
/// 1900–2199. No timezone or UTC-instant conversions live here; `Date` appears
/// only as the UI adapter type for `DatePicker`.
public enum TaskPlannedDate {
    public static let minimumYear = 1900
    public static let maximumYear = 2199

    /// Returns the value unchanged when it is a valid civil date, otherwise nil.
    public static func validated(_ value: String?) -> String? {
        guard let value, isValid(value) else { return nil }
        return value
    }

    /// Strict `YYYY-MM-DD`: exactly four digit year, two digit month and day,
    /// real Gregorian calendar days (month lengths and leap years), 1900–2199.
    public static func isValid(_ value: String) -> Bool {
        let characters = Array(value)
        guard characters.count == 10 else { return false }
        let parts = (0..<10).map { characters[$0] }
        // Positions 4 and 7 must be hyphens, everything else an ASCII digit.
        let digits = Set("0123456789")
        for index in 0..<10 {
            if index == 4 || index == 7 {
                guard parts[index] == "-" else { return false }
            } else {
                guard digits.contains(parts[index]) else { return false }
            }
        }
        let year = Int(String(parts[0...3])) ?? 0
        let month = Int(String(parts[5...6])) ?? 0
        let day = Int(String(parts[8...9])) ?? 0
        guard year >= minimumYear, year <= maximumYear else { return false }
        guard month >= 1, month <= 12 else { return false }
        guard day >= 1, day <= daysInMonth(year: year, month: month) else { return false }
        return true
    }

    private static func daysInMonth(year: Int, month: Int) -> Int {
        switch month {
        case 1, 3, 5, 7, 8, 10, 12:
            return 31
        case 4, 6, 9, 11:
            return 30
        default:
            return isLeapYear(year) ? 29 : 28
        }
    }

    private static func isLeapYear(_ year: Int) -> Bool {
        (year % 4 == 0 && year % 100 != 0) || year % 400 == 0
    }

    /// UI adapter: the local civil day of `date` in `calendar`'s time zone as
    /// `YYYY-MM-DD`. Components are always read in the Gregorian calendar —
    /// the stored contract is Gregorian regardless of the system calendar
    /// (Buddhist/Islamic etc. only change the displayed rendering).
    public static func civilDateString(from date: Date, calendar: Calendar = .current) -> String {
        let components = gregorian(withTimeZone: calendar.timeZone)
            .dateComponents([.year, .month, .day], from: date)
        let year = String(components.year ?? 1900)
        let month = String(format: "%02d", components.month ?? 1)
        let day = String(format: "%02d", components.day ?? 1)
        return "\(year)-\(month)-\(day)"
    }

    /// UI adapter: the instant of noon on civil day `value` in `calendar`'s
    /// time zone, or nil when the value is not a valid civil date. The day is
    /// constructed in the Gregorian calendar (storage contract); noon keeps
    /// the civil day stable across small UTC-offset/DST shifts.
    public static func date(fromCivilDateString value: String, calendar: Calendar = .current) -> Date? {
        guard isValid(value) else { return nil }
        let year = Int(value.prefix(4)) ?? 1900
        let month = Int(value.dropFirst(5).prefix(2)) ?? 1
        let day = Int(value.suffix(2)) ?? 1
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12 // noon keeps the civil day stable across small offsets
        return gregorian(withTimeZone: calendar.timeZone).date(from: components)
    }

    /// Gregorian calendar carrying the time zone of the supplied calendar:
    /// year/month/day semantics stay Gregorian while "local civil day" keeps
    /// meaning the user's own time zone.
    private static func gregorian(withTimeZone timeZone: TimeZone) -> Calendar {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = timeZone
        return gregorian
    }
}
