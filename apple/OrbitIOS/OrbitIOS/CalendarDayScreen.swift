import SwiftUI
import OrbitCore

/// The «Календарь» day view: one selected civil day shown as a 00:00–24:00
/// timeline (via `TaskDayProjector`) with untimed tasks listed separately.
/// Read-only slice over the shared model — tap opens the existing interval
/// editor for the source task, context menu reuses existing complete/reopen
/// and date operations; creation stays in the Inbox composer.
struct CalendarDayScreen: View {
    let model: IOSInboxModel

    @State private var presentation: InboxSheetPresentation?
    @State private var selectedDay: String = TaskDaySelection.currentDay()
    @State private var pickerDate: Date = TaskPlannedDate.date(
        fromCivilDateString: TaskDaySelection.currentDay()
    ) ?? Date()

    private let gregorianNoon: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar
    }()

    private static let rangeLowerBound = TaskPlannedDate.date(fromCivilDateString: "1900-01-01") ?? Date.distantPast
    private static let rangeUpperBound = TaskPlannedDate.date(fromCivilDateString: "2199-12-31") ?? Date.distantFuture

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                dayControls
                if let writeError = model.writeError {
                    writeErrorBanner(writeError)
                }
                if model.listError != nil {
                    listErrorView
                } else {
                    untimedSection
                    DayTimelineView(
                        segments: projection.timedSegments,
                        task: { taskID in model.tasks.first { $0.id == taskID } },
                        onEditInterval: { task in presentation = .interval(task) },
                        onComplete: { task in model.setCompleted(true, for: task) },
                        onReopen: { task in model.setCompleted(false, for: task) },
                        onEditDate: { task in presentation = .date(task) }
                    )
                }
            }
            .navigationTitle("Календарь")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(.systemBackground))
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

    // MARK: - Projection

    private var projection: TaskDayProjection {
        TaskDayProjector.project(day: selectedDay, in: model.tasks)
    }

    private func untimedTask(withID id: UUID) -> OrbitTask? {
        model.tasks.first { $0.id == id }
    }

    // MARK: - Day controls

    private var dayControls: some View {
        HStack(spacing: 12) {
            Button {
                if let candidate = shiftedDay(-1) { select(candidate) }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .medium))
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(shiftedDay(-1) == nil)
            .accessibilityLabel("Предыдущий день")

            DatePicker(
                "Дата",
                selection: $pickerDate,
                in: Self.rangeLowerBound...Self.rangeUpperBound,
                displayedComponents: [.date]
            )
            .labelsHidden()
            .onChange(of: pickerDate) { _, newDate in
                select(TaskPlannedDate.civilDateString(from: newDate, calendar: gregorianNoon))
            }

            Button {
                if let candidate = shiftedDay(1) { select(candidate) }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 17, weight: .medium))
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(shiftedDay(1) == nil)
            .accessibilityLabel("Следующий день")

            Spacer(minLength: 0)

            Button("Сегодня") {
                select(TaskDaySelection.currentDay())
            }
            .buttonStyle(.bordered)
            .tint(.orbitAccent)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.bar)
    }

    /// ±1 civil day anchored at noon, valid only inside 1900–2199.
    private func shiftedDay(_ delta: Int) -> String? {
        guard let anchor = TaskPlannedDate.date(
            fromCivilDateString: selectedDay,
            calendar: gregorianNoon
        ) else { return nil }
        guard let shifted = gregorianNoon.date(byAdding: .day, value: delta, to: anchor) else { return nil }
        let candidate = TaskPlannedDate.civilDateString(from: shifted, calendar: gregorianNoon)
        return TaskPlannedDate.isValid(candidate) ? candidate : nil
    }

    /// Guarded selection: an invalid candidate never changes the state.
    private func select(_ day: String) {
        guard TaskPlannedDate.isValid(day) else { return }
        selectedDay = day
        pickerDate = TaskPlannedDate.date(fromCivilDateString: day, calendar: gregorianNoon) ?? pickerDate
    }

    // MARK: - Untimed area

    private var untimedSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            if projection.untimedTaskIDs.isEmpty {
                Text("Без времени — нет задач")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
            } else {
                Text("Без времени")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
                ForEach(projection.untimedTaskIDs, id: \.self) { id in
                    if let task = untimedTask(withID: id) {
                        InboxRowView(task: task, model: model) {
                            presentation = .date(task)
                        } onEditInterval: {
                            presentation = .interval(task)
                        }
                    }
                }
            }
            Divider()
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Errors

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

    private func writeErrorBanner(_ message: String) -> some View {
        Text(message)
            .font(.footnote)
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemBackground))
            .accessibilityIdentifier("calendar-write-error")
    }
}
