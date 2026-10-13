import SwiftUI
import OrbitCore

/// The single Inbox screen: add field, open/completed sections, completion toggles.
struct InboxView: View {
    @State private var model: InboxModel
    @FocusState private var titleFieldFocused: Bool

    init(model: InboxModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        VStack(spacing: 0) {
            composer
            Divider()
            if model.listError != nil {
                listErrorBar
            } else {
                taskList
            }
        }
        .frame(minWidth: 460, minHeight: 500)
        .onAppear {
            titleFieldFocused = true
        }
    }

    private var composer: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Входящие")
                .font(.title.bold())
            HStack(spacing: 8) {
                TextField(
                    "Название задачи",
                    text: $model.draft,
                    prompt: Text("Название задачи")
                )
                .focused($titleFieldFocused)
                .onSubmit(submitDraft)
                Button("Добавить", action: submitDraft)
                    .disabled(isDraftBlank)
            }
            if let writeError = model.writeError {
                Text(writeError)
                    .font(.callout)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("write-error")
            }
        }
        .padding(16)
    }

    private var listErrorBar: some View {
        VStack(spacing: 8) {
            Text(model.listError ?? "")
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
            Button("Повторить") { model.reload() }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .accessibilityIdentifier("list-error")
    }

    @ViewBuilder
    private var taskList: some View {
        if model.tasks.isEmpty {
            ContentUnavailableView {
                Label("Пока нет задач", systemImage: "tray")
            } description: {
                Text("Добавьте первую задачу в поле выше.")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                if !model.openTasks.isEmpty {
                    Section("Открытые") {
                        ForEach(model.openTasks) { task in
                            InboxTaskRow(task: task, model: model)
                        }
                    }
                }
                if !model.completedTasks.isEmpty {
                    Section("Завершённые") {
                        ForEach(model.completedTasks) { task in
                            InboxTaskRow(task: task, model: model)
                        }
                    }
                }
            }
        }
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

/// One row: title text plus an independent native completion control.
struct InboxTaskRow: View {
    let task: OrbitTask
    let model: InboxModel

    var body: some View {
        HStack(spacing: 12) {
            Toggle(isOn: completionBinding) { }
                .toggleStyle(.checkbox)
                .labelsHidden()
                .accessibilityLabel(task.isCompleted ? Text("Снова открыть") : Text("Отметить выполненной"))
            Text(task.title)
                .strikethrough(task.isCompleted)
                .foregroundStyle(task.isCompleted ? Color.secondary : Color.primary)
                .textSelection(.enabled)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
    }

    private var completionBinding: Binding<Bool> {
        Binding(
            get: { task.isCompleted },
            set: { model.setCompleted($0, for: task) }
        )
    }
}
