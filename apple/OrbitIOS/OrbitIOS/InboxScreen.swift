import SwiftUI
import OrbitCore

/// Single accent of the screen: a restrained coral/red for the primary action
/// and completed state. Everything else stays system gray.
extension Color {
    static let orbitAccent = Color(red: 0.906, green: 0.345, blue: 0.286)
}

/// Which editor sheet is presented; identified by kind + task UUID so only
/// one date or interval editor exists at a time and each presentation
/// re-initializes its draft from persisted values.
enum InboxSheetPresentation: Identifiable {
    case date(OrbitTask)
    case interval(OrbitTask)

    var id: String {
        switch self {
        case .date(let task): "date-\(task.id.uuidString)"
        case .interval(let task): "interval-\(task.id.uuidString)"
        }
    }
}

/// The one iOS Inbox screen: large title, compact rows with round completion
/// circles and date/time actions, bottom composer above the keyboard and safe area.
struct InboxScreen: View {
    @State private var model: IOSInboxModel
    @State private var presentation: InboxSheetPresentation?
    @FocusState private var titleFieldFocused: Bool

    init(model: IOSInboxModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        NavigationStack {
            Group {
                if model.listError != nil {
                    listErrorView
                } else if model.tasks.isEmpty {
                    ContentUnavailableView {
                        Label("Пока нет задач", systemImage: "tray")
                    } description: {
                        Text("Добавьте первую задачу в поле снизу.")
                    }
                } else {
                    taskList
                }
            }
            .navigationTitle("Входящие")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(.systemBackground))
            .safeAreaInset(edge: .bottom, spacing: 0) {
                composer
            }
            .sheet(item: $presentation) { item in
                switch item {
                case .date(let task):
                    TaskDateSheet(task: task, model: model)
                case .interval(let task):
                    TaskIntervalSheet(task: task, model: model)
                }
            }
        }
    }

    private var taskList: some View {
        List {
            if !model.openTasks.isEmpty {
                Section("Открытые") {
                    ForEach(model.openTasks) { task in
                        InboxRowView(task: task, model: model) {
                            presentation = .date(task)
                        } onEditInterval: {
                            presentation = .interval(task)
                        }
                    }
                }
            }
            if !model.completedTasks.isEmpty {
                Section("Завершённые") {
                    ForEach(model.completedTasks) { task in
                        InboxRowView(task: task, model: model) {
                            presentation = .date(task)
                        } onEditInterval: {
                            presentation = .interval(task)
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    private var listErrorView: some View {
        ContentUnavailableView {
            Label("Не удалось загрузить задачи", systemImage: "externaldrive.badge.exclamationmark")
        } description: {
            Text(model.listError ?? "")
        } actions: {
            Button("Повторить") { model.reload() }
                .buttonStyle(.borderedProminent)
                .tint(.orbitAccent)
        }
    }

    /// Compact composer pinned to the bottom safe area; the keyboard raises it,
    /// so it never covers the list rows.
    private var composer: some View {
        VStack(spacing: 8) {
            if let writeError = model.writeError {
                Text(writeError)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("write-error")
            }
            HStack(spacing: 12) {
                TextField("Название задачи", text: $model.draft, prompt: Text("Название задачи"))
                    .focused($titleFieldFocused)
                    .submitLabel(.done)
                    .onSubmit(submitDraft)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(Color(.secondarySystemBackground), in: Capsule())
                Button(action: submitDraft) {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(isDraftBlank ? Color(.systemGray3) : Color.white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle().fill(isDraftBlank ? Color(.tertiarySystemFill) : Color.orbitAccent)
                        )
                }
                .buttonStyle(.plain)
                .disabled(isDraftBlank)
                .accessibilityLabel("Добавить задачу")
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(.bar)
    }

    private var isDraftBlank: Bool {
        model.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func submitDraft() {
        model.addFromDraft()
        if model.writeError == nil {
            titleFieldFocused = true
        }
    }
}

/// One row: round completion control on the left and the tappable task body
/// (title + metadata). NATIVE-LIST-001: the always-visible clock/calendar
/// icons are gone — tapping the body opens a compact native menu with the
/// existing date and time/duration editors, while the circle stays an
/// independent complete/reopen control that never opens the menu. Titles
/// wrap instead of being truncated; hit areas are ≥ 44pt; rows are lower
/// through tighter vertical padding only.
struct InboxRowView: View {
    let task: OrbitTask
    let model: IOSInboxModel
    /// Row presentation flag (NATIVE-LIST-001): show the planned-date
    /// subtitle. Default true (Inbox keeps the useful date); Today and the
    /// day-grouped Upcoming sections pass false — their section headers
    /// already carry the date. Presentation only, no metadata loss.
    var showsDateLabel: Bool = true
    let onEditDate: () -> Void
    let onEditInterval: () -> Void

    private static let dateLabelFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    /// Kept for the existing interval editor caption; the row subtitle
    /// itself is formatted view-locally in Russian (see `body`).
    static func dateLabel(_ civilDate: String) -> String {
        guard let date = TaskPlannedDate.date(fromCivilDateString: civilDate) else {
            return civilDate
        }
        return dateLabelFormatter.string(from: date)
    }

    /// Derived "start–end" wall-clock range; a midnight crossing is marked
    /// with "(+1 день)". The end comes from `TaskTimeInterval.end` and is
    /// never stored.
    static func intervalLabel(_ task: OrbitTask) -> String? {
        guard let date = task.plannedDate,
            let time = task.plannedTime,
            let duration = task.durationMinutes,
            let end = TaskTimeInterval.end(plannedDate: date, plannedTime: time, durationMinutes: duration)
        else { return nil }
        if end.date == date {
            return "\(time)–\(end.time)"
        }
        return "\(time)–\(end.time) (+1 день)"
    }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            CompletionButton(isCompleted: task.isCompleted) {
                model.setCompleted(!task.isCompleted, for: task)
            }
            .accessibilityLabel(
                task.isCompleted ? "Снова открыть: \(task.title)" : "Отметить выполненной: \(task.title)"
            )
            taskBodyMenu
        }
        .padding(.vertical, 2)
        .alignmentGuide(.listRowSeparatorLeading) { dimensions in
            dimensions[.leading] + 44 + 14
        }
    }

    /// The tappable body: a compact native menu over the existing editor
    /// callbacks. Presentation only — opening/cancelling the menu never
    /// mutates anything, and the circle never triggers it.
    private var taskBodyMenu: some View {
        Menu {
            Button("Дата…") { onEditDate() }
            timeMenuButton
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.body)
                    .foregroundStyle(task.isCompleted ? Color.secondary : Color.primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                if showsDateLabel, let plannedDate = task.plannedDate {
                    Text(RussianDateCaption.label(plannedDate))
                        .font(.footnote)
                        // Semantic colors survive the Menu label tint;
                        // hierarchical styles would render coral.
                        .foregroundStyle(Color.secondary)
                }
                if let interval = Self.intervalLabel(task) {
                    Text(interval)
                        .font(.footnote)
                        .foregroundStyle(Color.secondary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
        }
        .accessibilityLabel(task.title)
    }

    /// Time/duration is offered only once the task has a planned date (the
    /// interval editor requires one); an undated task starts with «Дата…» —
    /// today is never assigned silently.
    @ViewBuilder
    private var timeMenuButton: some View {
        if task.plannedDate != nil {
            Button("Время и длительность…") { onEditInterval() }
        } else {
            Button("Время и длительность — сначала назначьте дату") { }
                .disabled(true)
        }
    }
}

/// Round Todoist-like completion control: calm gray outline, coral fill with a
/// white checkmark once completed; ≥ 44pt tappable.
struct CompletionButton: View {
    let isCompleted: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isCompleted ? Color.orbitAccent : Color.clear)
                Circle()
                    .strokeBorder(isCompleted ? Color.orbitAccent : Color(.systemGray3), lineWidth: 1.5)
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.white)
                }
            }
            .frame(width: 26, height: 26)
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isCompleted)
    }
}

/// Explicit open-failure state: explains the problem, never deletes the store,
/// never falls back to an empty in-memory database.
struct StoreFailureView: View {
    let message: String

    var body: some View {
        ContentUnavailableView {
            Label("Хранилище недоступно", systemImage: "externaldrive.badge.exclamationmark")
        } description: {
            Text(message)
        }
    }
}
