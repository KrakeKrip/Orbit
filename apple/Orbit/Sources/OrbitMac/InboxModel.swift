import Foundation
import Observation
import OrbitCore

/// UI-facing error texts in Russian; the view layer never formats store errors itself.
enum InboxFormatting {
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

    static func openMessage(_ error: Error) -> String {
        "Не удалось открыть хранилище. Данные не изменены. \(error.localizedDescription)"
    }
}

/// Main-actor state of the Inbox screen. Every mutation goes through the store's
/// explicit save; failures keep the draft and roll the list back to persisted truth.
@MainActor
@Observable
final class InboxModel {
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
            listError = InboxFormatting.storageMessage(error)
        }
    }

    func addFromDraft() {
        do {
            _ = try store.addTask(title: draft)
            draft = ""
            writeError = nil
            reload()
        } catch {
            writeError = InboxFormatting.addMessage(error)
            reload()
        }
    }

    func setCompleted(_ isCompleted: Bool, for task: OrbitTask) {
        do {
            try store.setCompleted(isCompleted, for: task.id)
            writeError = nil
            reload()
        } catch {
            writeError = InboxFormatting.completionMessage(error)
            reload()
        }
    }
}
