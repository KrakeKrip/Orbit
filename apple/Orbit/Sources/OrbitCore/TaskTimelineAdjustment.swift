import Foundation

/// Gesture-only snapping. Manual editors and persisted read rules stay unchanged.
public enum TaskTimelineAdjustment {
    public enum Edge { case move, start, end }
    public struct Candidate: Equatable {
        public let time: String
        public let duration: Int
        public var startMinute: Int {
            let parts = time.split(separator: ":").compactMap { Int($0) }
            return parts[0] * 60 + parts[1]
        }
    }

    /// Delta is measured from the frozen gesture origin, never accumulated.
    /// Moving keeps duration; resizing keeps the opposite endpoint fixed.
    /// The start stays on its original civil date; the end may cross midnight.
    public static func candidate(date: String, time: String, duration: Int,
                                 deltaMinutes: Double, edge: Edge) -> Candidate? {
        guard TaskTimeInterval.isValidTime(time), TaskTimeInterval.isValidDuration(duration),
              deltaMinutes.isFinite, abs(deltaMinutes) <= 10_000 else { return nil }
        let parts = time.split(separator: ":").compactMap { Int($0) }
        let start = parts[0] * 60 + parts[1]
        let end = start + duration
        func snap(_ value: Double, step: Int) -> Int {
            Int((value / Double(step)).rounded()) * step
        }
        let nextStart: Int
        let nextDuration: Int
        switch edge {
        case .move:
            nextStart = min(1435, max(0, snap(Double(start) + deltaMinutes, step: 5)))
            nextDuration = duration
        case .end:
            nextStart = start
            nextDuration = min(1440, max(5, snap(Double(duration) + deltaMinutes, step: 10)))
        case .start:
            let lowerDuration = max(5, end - 1439)
            let upperDuration = min(1440, end)
            guard lowerDuration <= upperDuration else { return nil }
            nextDuration = min(upperDuration, max(lowerDuration,
                snap(Double(duration) - deltaMinutes, step: 10)))
            nextStart = end - nextDuration
        }
        let nextTime = String(format: "%02d:%02d", nextStart / 60, nextStart % 60)
        guard TaskTimeInterval.isWritableDuration(nextDuration),
              TaskTimeInterval.end(plannedDate: date, plannedTime: nextTime,
                                   durationMinutes: nextDuration) != nil else { return nil }
        return Candidate(time: nextTime, duration: nextDuration)
    }
}
