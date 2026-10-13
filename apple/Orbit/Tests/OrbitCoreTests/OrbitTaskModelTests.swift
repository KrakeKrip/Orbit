import Foundation
import Testing
import OrbitCore

@Suite("OrbitTask model")
struct OrbitTaskModelTests {

    @Test("complete sets completedAt once, reopen clears it")
    @MainActor
    func completeReopen() {
        let at = Date(timeIntervalSince1970: 1_760_000_000)
        let task = OrbitTask(title: "Задача", createdAt: at)
        #expect(!task.isCompleted)
        #expect(task.completedAt == nil)

        task.complete(at: at)
        #expect(task.isCompleted)
        #expect(task.completedAt == at)

        task.complete(at: at.addingTimeInterval(60))
        #expect(task.completedAt == at)

        task.reopen()
        #expect(!task.isCompleted)
        #expect(task.completedAt == nil)

        task.reopen()
        #expect(!task.isCompleted)
    }
}
