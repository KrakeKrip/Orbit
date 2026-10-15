import Testing
@testable import OrbitCore

struct TaskTimelineAdjustmentTests {
    func adjust(_ edge: TaskTimelineAdjustment.Edge, _ delta: Double,
                time: String = "09:08", duration: Int = 30, date: String = "2026-10-15") -> TaskTimelineAdjustment.Candidate? {
        TaskTimelineAdjustment.candidate(date: date, time: time, duration: duration,
                                         deltaMinutes: delta, edge: edge)
    }
    @Test func moveSnapsClockAndPreservesDuration() {
        #expect(adjust(.move, 5)?.time == "09:15")
        #expect(adjust(.move, -5)?.time == "09:05")
        #expect(adjust(.move, 5, duration: 7)?.duration == 7)
        #expect(adjust(.move, -900)?.time == "00:00")
        #expect(adjust(.move, 900)?.time == "23:55")
    }
    @Test func resizingUsesTenMinuteStepsAndFiveMinuteMinimum() {
        #expect(adjust(.end, 9)?.duration == 40)
        #expect(adjust(.end, -100)?.duration == 5)
        #expect(adjust(.end, 2000)?.duration == 1440)
        #expect(adjust(.start, 10)?.time == "09:18")
        #expect(adjust(.start, 10)?.duration == 20)
        #expect(adjust(.start, 100)?.time == "09:33")
        #expect(adjust(.start, 100)?.duration == 5)
    }
    @Test func oppositeEndpointAndCivilDateStayFixed() {
        let result = adjust(.start, -20, time: "23:30", duration: 90)
        #expect(result?.time == "23:10")
        #expect(result?.duration == 110)
        #expect(adjust(.start, -100, time: "00:10", duration: 30)?.time == "00:00")
        #expect(adjust(.end, 30, time: "23:30", date: "2199-12-31") == nil)
        #expect(adjust(.end, 30, time: "23:30")?.duration == 60)
    }
    @Test func invalidAndLegacyCandidatesAreNeverSilentlyWritten() {
        #expect(adjust(.move, .infinity) == nil)
        #expect(adjust(.move, .nan) == nil)
        #expect(adjust(.move, 0, time: "25:00") == nil)
        #expect(adjust(.move, 5, duration: 1) == nil)
        #expect(adjust(.end, 10, duration: 1)?.duration == 10)
        #expect(adjust(.move, 0, date: "invalid") == nil)
    }
}
