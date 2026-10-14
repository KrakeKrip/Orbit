import SwiftUI
import OrbitCore

/// Small time-interval editor for one dated task: two labeled text fields
/// («Начало» HH:mm and «Длительность, мин»), explicit «Сохранить»/«Отмена»
/// and «Убрать время» for a saved interval. The draft is taken from the
/// persisted values on every presentation (defaults 09:00 / 30 when unset);
/// opening, editing, cancelling and swipe-dismissing never write. A failed
/// save shows the Russian error and keeps the draft and the sheet open.
/// Validation lives in the core — the pair is passed to the store whole.
struct TaskIntervalSheet: View {
    let task: OrbitTask
    let model: IOSInboxModel

    @Environment(\.dismiss) private var dismiss
    @State private var draftTime: String
    @State private var draftDuration: String
    @State private var errorMessage: String?

    init(task: OrbitTask, model: IOSInboxModel) {
        self.task = task
        self.model = model
        _draftTime = State(initialValue: task.plannedTime ?? "09:00")
        _draftDuration = State(initialValue: task.durationMinutes.map(String.init) ?? "30")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(task.title)
                        .font(.body.weight(.medium))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                        .accessibilityIdentifier("interval-task-title")
                } header: {
                    Text("Задача")
                }

                Section {
                    LabeledContent("Начало") {
                        TextField("09:00", text: $draftTime)
                            .keyboardType(.numbersAndPunctuation)
                            .multilineTextAlignment(.trailing)
                            .accessibilityIdentifier("interval-start-field")
                    }
                    LabeledContent("Длительность, мин") {
                        TextField("30", text: $draftDuration)
                            .keyboardType(.numbersAndPunctuation)
                            .multilineTextAlignment(.trailing)
                            .accessibilityIdentifier("interval-duration-field")
                    }
                } header: {
                    Text("Время задачи")
                } footer: {
                    Text("Начало в формате ЧЧ:ММ (00:00–23:59), длительность — целое число минут от \(TaskTimeInterval.minimumWritableDurationMinutes) до \(TaskTimeInterval.maximumDurationMinutes). Конец может переходить через полночь.")
                }

                Section {
                    LabeledContent("Дата") {
                        Text(dateContext)
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .accessibilityIdentifier("interval-error")
                    }
                }

                Section {
                    Button(action: save) {
                        Text("Сохранить")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orbitAccent)
                    .accessibilityIdentifier("interval-save")
                    Button("Отмена") { dismiss() }
                        .frame(maxWidth: .infinity)
                        .accessibilityIdentifier("interval-cancel")
                    if task.plannedTime != nil {
                        Button(role: .destructive, action: clearInterval) {
                            Label("Убрать время", systemImage: "clock.badge.minus")
                                .frame(maxWidth: .infinity)
                        }
                        .accessibilityIdentifier("interval-clear")
                    }
                }
            }
            .navigationTitle("Время задачи")
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled(false)
        }
        .presentationDetents([.medium, .large])
    }

    /// Human-readable assigned date for the context line.
    private var dateContext: String {
        guard let plannedDate = task.plannedDate else { return "—" }
        return InboxRowView.dateLabel(plannedDate)
    }

    private func save() {
        let time = draftTime.trimmingCharacters(in: .whitespaces)
        // Type conversion only: a non-numeric/blank duration cannot become a
        // nil/nil pair or a default; the range rule stays in the core.
        guard let duration = Int(draftDuration.trimmingCharacters(in: .whitespaces)) else {
            errorMessage = "Длительность должна быть целым числом минут."
            return
        }
        if let message = model.setPlannedInterval(plannedTime: time, durationMinutes: duration, for: task) {
            errorMessage = message
        } else {
            dismiss()
        }
    }

    private func clearInterval() {
        if let message = model.setPlannedInterval(plannedTime: nil, durationMinutes: nil, for: task) {
            errorMessage = message
        } else {
            dismiss()
        }
    }
}
