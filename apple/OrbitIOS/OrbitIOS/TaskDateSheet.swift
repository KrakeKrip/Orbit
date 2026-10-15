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
            Form {
                Section("Задача") {
                    Text(task.title)
                        .font(.body.weight(.medium))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Section("Дата") {
                    DatePicker("Дата", selection: $draftDate, in: dateRange, displayedComponents: [.date])
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .environment(\.locale, Locale(identifier: "ru_RU"))
                        .environment(\.calendar, Calendar.orbitCivil)
                }
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .accessibilityIdentifier("date-error")
                    }
                }
                Section {
                    Button(action: save) {
                        Text("Сохранить").frame(maxWidth: .infinity)
                    }
                    .orbitPrimaryStyle()
                    Button("Отмена") { dismiss() }
                        .orbitSecondaryStyle()
                        .frame(maxWidth: .infinity)
                    if task.plannedDate != nil {
                        Button(role: .destructive, action: clearDate) {
                            Label("Убрать дату", systemImage: "calendar.badge.minus")
                                .frame(maxWidth: .infinity)
                        }
                        .orbitSecondaryStyle()
                    }
                }
            }
            .orbitEditorSurface()
            .navigationTitle("Дата задачи")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
        .orbitEditorSurface()
    }

    private var dateRange: ClosedRange<Date> {
        let lower = TaskPlannedDate.date(fromCivilDateString: "1900-01-01")!
        let upper = TaskPlannedDate.date(fromCivilDateString: "2199-12-31")!
        return lower...upper
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
