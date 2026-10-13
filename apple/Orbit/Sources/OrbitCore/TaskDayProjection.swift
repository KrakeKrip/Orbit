import Foundation

/// One half-open timed segment `[startMinute, endMinute)` of a task's
/// interval projected onto the selected civil day (0...1440, always
/// start < end). Identification is stable: the existing task UUID plus the
/// selected day — never a freshly generated identifier.
public struct TaskDayIntervalSegment: Equatable {
    public let taskID: UUID
    public let day: String
    public let startMinute: Int
    public let endMinute: Int
    /// Positive part of the interval lies in the previous civil day.
    public let continuesFromPreviousDay: Bool
    /// Positive part of the interval lies in the next civil day.
    public let continuesIntoNextDay: Bool

    init(taskID: UUID, day: String, startMinute: Int, endMinute: Int,
         continuesFromPreviousDay: Bool, continuesIntoNextDay: Bool) {
        self.taskID = taskID
        self.day = day
        self.startMinute = startMinute
        self.endMinute = endMinute
        self.continuesFromPreviousDay = continuesFromPreviousDay
        self.continuesIntoNextDay = continuesIntoNextDay
    }
}

/// Read-only result of projecting task intervals onto one selected civil day.
public struct TaskDayProjection: Equatable {
    /// The selected day exactly as passed in (echoed even when invalid —
    /// in that case both lists are empty).
    public let day: String
    /// Untimed tasks planned on the day, in the input order.
    public let untimedTaskIDs: [UUID]
    /// Timed segments on the day, chronologically sorted.
    public let timedSegments: [TaskDayIntervalSegment]

    public init(day: String, untimedTaskIDs: [UUID], timedSegments: [TaskDayIntervalSegment]) {
        self.day = day
        self.untimedTaskIDs = untimedTaskIDs
        self.timedSegments = timedSegments
    }
}

/// Pure read-only projection of task intervals onto one selected civil day for
/// the future 00:00–24:00 day grid (result: `TaskDayProjection`).
///
/// Rules (all reuse the accepted helpers; no duplicated civil arithmetic,
/// no Date/Calendar/timezone/DST conversions):
/// - `day` must be a valid Gregorian `YYYY-MM-DD` (1900–2199, via
///   `TaskPlannedDate`); invalid or nil day → empty lists.
/// - Untimed: `plannedDate == day` with both interval fields nil; UUIDs in
///   the input order. Completed tasks are NOT excluded (completion styling
///   belongs to the future UI).
/// - Timed: valid date/time/duration with a derived end from the accepted
///   `TaskTimeInterval.end`. Same-day intervals project
///   `start…end` on the day; intervals ending after midnight project
///   `start…1440` on their start day with `continuesIntoNextDay` and a
///   positive `0…end` continuation segment on the next day with
///   `continuesFromPreviousDay`. An end exactly at midnight produces no
///   zero-length segment. Corrupt partial inputs and ends outside
///   1900–2199 are excluded, never repaired.
/// - Overlapping tasks stay as separate segments (lane assignment is a
///   future UI concern). Segments are sorted chronologically:
///   start ASC, end ASC, task UUID string ASC for stable ties.
public enum TaskDayProjector {

    public static func project(day: String?, in tasks: [OrbitTask]) -> TaskDayProjection {
        guard let day, TaskPlannedDate.isValid(day) else {
            return TaskDayProjection(day: day ?? "", untimedTaskIDs: [], timedSegments: [])
        }

        var untimed: [UUID] = []
        var segments: [TaskDayIntervalSegment] = []

        for task in tasks {
            guard let plannedDate = task.plannedDate else { continue }
            let hasInterval = task.plannedTime != nil && task.durationMinutes != nil
            let isCompletePair = TaskTimeInterval.isCompletePair(
                time: task.plannedTime,
                durationMinutes: task.durationMinutes
            )

            if plannedDate == day {
                if task.plannedTime == nil && task.durationMinutes == nil {
                    untimed.append(task.id)
                    continue
                }
                // Dated task with a corrupt/invalid interval: excluded, never repaired.
                guard hasInterval, isCompletePair,
                    let time = task.plannedTime,
                    let duration = task.durationMinutes,
                    let end = TaskTimeInterval.end(
                        plannedDate: plannedDate,
                        plannedTime: time,
                        durationMinutes: duration
                    )
                else { continue }

                let startMinute = startMinutes(of: time)
                if end.date == day {
                    segments.append(TaskDayIntervalSegment(
                        taskID: task.id,
                        day: day,
                        startMinute: startMinute,
                        endMinute: endMinutes(of: end.time),
                        continuesFromPreviousDay: false,
                        continuesIntoNextDay: false
                    ))
                } else {
                    // End lands after the start day. With duration ≤ 1440 this
                    // is the very next day; the flag is true only when a
                    // positive part actually exists there — an end exactly at
                    // midnight (00:00) has none.
                    segments.append(TaskDayIntervalSegment(
                        taskID: task.id,
                        day: day,
                        startMinute: startMinute,
                        endMinute: 1440,
                        continuesFromPreviousDay: false,
                        continuesIntoNextDay: endMinutes(of: end.time) > 0
                    ))
                }
            } else if plannedDate < day, hasInterval, isCompletePair,
                let time = task.plannedTime,
                let duration = task.durationMinutes,
                let end = TaskTimeInterval.end(
                    plannedDate: plannedDate,
                    plannedTime: time,
                    durationMinutes: duration
                ),
                end.date == day
            {
                // Overnight continuation from a strictly earlier start date:
                // with duration ≤ 1440 the end can land on at most the next
                // day, so `end.date == day` implies this interval started the
                // day before. Exact midnight (end minutes 0) is skipped — a
                // zero-length segment is never produced.
                let endMinute = endMinutes(of: end.time)
                guard endMinute > 0 else { continue }
                segments.append(TaskDayIntervalSegment(
                    taskID: task.id,
                    day: day,
                    startMinute: 0,
                    endMinute: endMinute,
                    continuesFromPreviousDay: true,
                    continuesIntoNextDay: false
                ))
            }
        }

        segments.sort { left, right in
            if left.startMinute != right.startMinute { return left.startMinute < right.startMinute }
            if left.endMinute != right.endMinute { return left.endMinute < right.endMinute }
            return left.taskID.uuidString < right.taskID.uuidString
        }

        return TaskDayProjection(
            day: day,
            untimedTaskIDs: untimed,
            timedSegments: segments
        )
    }

    private static func startMinutes(of time: String) -> Int {
        let characters = Array(time)
        return (Int(String(characters[0...1])) ?? 0) * 60 + (Int(String(characters[3...4])) ?? 0)
    }

    private static func endMinutes(of time: String) -> Int {
        let characters = Array(time)
        return (Int(String(characters[0...1])) ?? 0) * 60 + (Int(String(characters[3...4])) ?? 0)
    }
}
