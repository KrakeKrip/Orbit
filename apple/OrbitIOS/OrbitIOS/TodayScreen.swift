import SwiftUI
import OrbitCore

/// The «Сегодня» list: tasks planned on the device's current local civil
/// date. Read-only slice over the shared model — the same rows, editors and
/// sheets as the Inbox; creation stays in the Inbox composer.
/// NATIVE-NAV-001: the current day is owned by `TodayWorkspaceScreen` and
/// provided as the `day` input; the compact «Список / Календарь» switcher
/// lives in the navigation bar. Task dates are never rewritten.
struct TodayScreen: View {
    let model: IOSInboxModel
    let day: String
    let onGoToInbox: () -> Void
    var todayMode: Binding<Bool>? = nil

    @State private var presentation: InboxSheetPresentation?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let writeError = model.writeError {
                    writeErrorBanner(writeError)
                }
                Group {
                    if model.listError != nil {
                        listErrorView
                    } else if model.tasks.isEmpty || todayTasks.isEmpty {
                        emptyView
                    } else {
                        taskList
                    }
                }
            }
            .navigationTitle("Сегодня")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(.systemBackground))
            .toolbar {
                if let todayMode {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        TodayModeSwitcher(showsCalendar: todayMode)
                    }
                }
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

    private var todayTasks: [OrbitTask] {
        TaskDaySelection.tasks(onDay: day, in: model.tasks)
    }

    private var openTasks: [OrbitTask] {
        todayTasks.filter { !$0.isCompleted }
    }

    private var completedTasks: [OrbitTask] {
        todayTasks.filter { $0.isCompleted }
    }

    private var taskList: some View {
        List {
            Section {
                Text(dateCaption)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .listRowSeparator(.hidden)
            }
            if !openTasks.isEmpty {
                Section("Открытые") {
                    ForEach(openTasks) { task in
                        InboxRowView(task: task, model: model) {
                            presentation = .date(task)
                        } onEditInterval: {
                            presentation = .interval(task)
                        }
                    }
                }
            }
            if !completedTasks.isEmpty {
                Section("Завершённые") {
                    ForEach(completedTasks) { task in
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

    /// A failed complete/reopen (or another write) on this screen: the shared
    /// model keeps `writeError` until the next successful mutation, so the
    /// reason stays visible next to the content without masking the list,
    /// empty state or a read failure. The view never clears it.
    private func writeErrorBanner(_ message: String) -> some View {
        Text(message)
            .font(.footnote)
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemBackground))
            .accessibilityIdentifier("today-write-error")
    }

    private var emptyView: some View {
        VStack(spacing: 0) {
            // Local day stays visible even on a completely empty store.
            Text(dateCaption)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 4)
            ContentUnavailableView {
                Label("На сегодня задач нет", systemImage: "sun.max")
            } description: {
                if model.tasks.isEmpty {
                    Text("Добавьте задачу во Входящих.")
                } else {
                    Text("Задачи с датой \(dateCaption) отсутствуют.")
                }
            } actions: {
                Button("Добавить во Входящих") { onGoToInbox() }
                    .buttonStyle(.borderedProminent)
                    .tint(.orbitAccent)
            }
            Spacer(minLength: 0)
        }
    }

    /// NATIVE-NAV-002: the section-level date caption is formatted view-
    /// locally in Russian (explicit ru_RU/Gregorian adapters), not through
    /// the system-locale shared row label.
    private var dateCaption: String {
        RussianDateCaption.label(day)
    }
}
