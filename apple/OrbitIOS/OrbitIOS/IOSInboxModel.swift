import Foundation
import Observation
import OrbitCore

/// iOS-facing error texts in Russian; views never format store errors themselves.
enum IOSInboxFormatting {
    static func validationMessage(_ error: Error) -> String {
        switch error {
        case TaskTitleError.empty:
            return "Введите название задачи."
        case TaskTitleError.tooLong(let limit):
            return "Название не должно превышать \(limit) символов."
        default:
            return storageMessage(error)
        }
    }

    static func storageMessage(_ error: Error) -> String {
        switch error as? OrbitStoreError {
        case .taskNotFound:
            return "Задача не найдена в хранилище."
        case nil:
            break
        }
        return "Ошибка хранилища: \(error.localizedDescription)"
    }

    static func addMessage(_ error: Error) -> String {
        "Не удалось добавить задачу. \(validationMessage(error))"
    }

    static func completionMessage(_ error: Error) -> String {
        "Не удалось сохранить изменение. \(storageMessage(error))"
    }

    static func plannedDateMessage(_ error: Error) -> String {
        switch error {
        case TaskPlannedDateError.invalid:
            return "Дата должна быть в формате ГГГГ-ММ-ДД (год 1900–2199)."
        case TaskTimeIntervalError.endOutOfRange:
            return "Не удалось сохранить дату: итоговое время задачи выходит за пределы 1900–2199."
        default:
            return "Не удалось сохранить дату. \(storageMessage(error))"
        }
    }

    static func intervalMessage(_ error: Error) -> String {
        switch error {
        case TaskTimeIntervalError.invalidTime(let value):
            return "Начало «\(value)» должно быть временем в формате ЧЧ:ММ (00:00–23:59)."
        case TaskTimeIntervalError.invalidDuration(let value):
            return "Длительность \(value) недопустима: укажите целое число минут от \(TaskTimeInterval.minimumWritableDurationMinutes) до \(TaskTimeInterval.maximumDurationMinutes)."
        case TaskTimeIntervalError.incompletePair:
            return "Укажите начало и длительность вместе."
        case TaskTimeIntervalError.missingDate:
            return "Сначала назначьте дату задачи."
        case TaskTimeIntervalError.endOutOfRange:
            return "Итоговое время задачи выходит за пределы календаря (1900–2199)."
        default:
            return "Не удалось сохранить время. \(storageMessage(error))"
        }
    }

    static func openMessage(_ error: Error) -> String {
        "Не удалось открыть хранилище. Данные не изменены. \(error.localizedDescription)"
    }
}

/// Main-actor state of the iOS Inbox. Every mutation goes through the shared
/// OrbitCore store's explicit save; failures keep the draft and roll the list
/// back to persisted truth.
@MainActor
@Observable
final class IOSInboxModel {
    private let store: OrbitTaskStore

    private(set) var tasks: [OrbitTask] = []
    private(set) var listError: String?
    private(set) var writeError: String?
    var draft: String = ""

    init(store: OrbitTaskStore) {
        self.store = store
        reload()
    }

    var openTasks: [OrbitTask] {
        tasks.filter { !$0.isCompleted }
    }

    var completedTasks: [OrbitTask] {
        tasks.filter { $0.isCompleted }
    }

    func reload() {
        do {
            tasks = try store.tasks()
            listError = nil
        } catch {
            listError = IOSInboxFormatting.storageMessage(error)
        }
    }

    func addFromDraft() {
        do {
            _ = try store.addTask(title: draft)
            draft = ""
            writeError = nil
            reload()
        } catch {
            writeError = IOSInboxFormatting.addMessage(error)
            reload()
        }
    }

    func setCompleted(_ isCompleted: Bool, for task: OrbitTask) {
        do {
            try store.setCompleted(isCompleted, for: task.id)
            writeError = nil
            reload()
        } catch {
            writeError = IOSInboxFormatting.completionMessage(error)
            reload()
        }
    }

    /// Assigns, changes or clears (`nil`) the planned date. Returns nil on
    /// success (the list is reloaded from persisted truth); otherwise returns
    /// a user-facing message for the date editor, which stays open for retry.
    func setPlannedDate(_ value: String?, for task: OrbitTask) -> String? {
        do {
            try store.setPlannedDate(value, for: task.id)
            reload()
            return nil
        } catch {
            reload()
            return IOSInboxFormatting.plannedDateMessage(error)
        }
    }

    /// Assigns, changes or clears (nil/nil) the time interval as a whole pair.
    /// Returns nil on success (the list is reloaded from persisted truth);
    /// otherwise returns a user-facing message for the interval editor, which
    /// stays open for retry. The pair is always passed to the store whole —
    /// the core remains the single source of validation rules.
    func setPlannedInterval(plannedTime: String?, durationMinutes: Int?, for task: OrbitTask) -> String? {
        do {
            try store.setPlannedInterval(plannedTime: plannedTime, durationMinutes: durationMinutes, for: task.id)
            reload()
            return nil
        } catch {
            reload()
            return IOSInboxFormatting.intervalMessage(error)
        }
    }
}
