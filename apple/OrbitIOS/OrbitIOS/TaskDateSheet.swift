import SwiftUI
import OrbitCore

/// Small date editor for one task: native wheel `DatePicker`, explicit
/// «Сохранить»/«Отмена» buttons in the sheet content, and «Убрать дату» for an
/// assigned date. Opening and cancelling never write; a failed save keeps the
/// draft and shows the error for retry. The draft starts from the actual saved
/// date, or today's local civil day when none is set.
struct TaskDateSheet: View {
    let task: OrbitTask
    let model: IOSInboxModel

    @Environment(\.dismiss) private var dismiss
    @State private var draftDate: Date
    @State private var errorMessage: String?

    init(task: OrbitTask, model: IOSInboxModel) {
        self.task = task
        self.model = model
        let initial: Date
        if let saved = task.plannedDate {
            initial = TaskPlannedDate.date(fromCivilDateString: saved) ?? Date.now
        } else {
            initial = Date.now
        }
        _draftDate = State(initialValue: initial)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text(task.title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                DatePicker("Дата", selection: $draftDate, displayedComponents: [.date])
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .accessibilityIdentifier("date-error")
                }
                Button(action: save) {
                    Text("Сохранить")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orbitAccent)
                Button("Отмена") { dismiss() }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                if task.plannedDate != nil {
                    Button(role: .destructive, action: clearDate) {
                        Label("Убрать дату", systemImage: "calendar.badge.minus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                Spacer(minLength: 0)
            }
            .padding(16)
            .navigationTitle("Дата задачи")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
    }

    private func save() {
        let value = TaskPlannedDate.civilDateString(from: draftDate)
        if let message = model.setPlannedDate(value, for: task) {
            errorMessage = message
        } else {
            dismiss()
        }
    }

    private func clearDate() {
        if let message = model.setPlannedDate(nil, for: task) {
            errorMessage = message
        } else {
            dismiss()
        }
    }
}
