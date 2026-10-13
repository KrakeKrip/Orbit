import Combine
import SwiftUI
import OrbitCore

/// The «Сегодня» list: tasks planned on the device's current local civil
/// date. Read-only slice over the shared model — the same rows, editors and
/// sheets as the Inbox; creation stays in the Inbox composer. The current
/// day is recomputed on appear, on scene activation and at least once a
/// minute while the screen is visible; task dates are never rewritten.
struct TodayScreen: View {
    let model: IOSInboxModel
    let onGoToInbox: () -> Void

    @Environment(\.scenePhase) private var scenePhase
    @State private var presentation: InboxSheetPresentation?
    @State private var currentDay: String = TaskDaySelection.currentDay()
    private let dayRefreshTimer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

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
            .sheet(item: $presentation) { item in
                switch item {
                case .date(let task):
                    TaskDateSheet(task: task, model: model)
                case .interval(let task):
                    TaskIntervalSheet(task: task, model: model)
                }
            }
        }
        .onAppear { refresh() }
        .onReceive(dayRefreshTimer) { _ in refresh(reloadTasks: false) }
        .onChange(of: currentDay) { _, _ in model.reload() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                refresh()
            }
        }
    }

    private var todayTasks: [OrbitTask] {
        TaskDaySelection.tasks(onDay: currentDay, in: model.tasks)
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
            Button("Повторить") { refresh() }
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

    private var dateCaption: String {
        InboxRowView.dateLabel(currentDay)
    }

    /// Recomputes the current local day; reloads the shared model on explicit
    /// refreshes (appear, retry, scene activation) or when the day changed.
    private func refresh(reloadTasks: Bool = true) {
        let newDay = TaskDaySelection.currentDay()
        let dayChanged = newDay != currentDay
        currentDay = newDay
        if reloadTasks || dayChanged {
            model.reload()
        }
    }
}
