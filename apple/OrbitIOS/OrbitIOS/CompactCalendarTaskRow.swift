import SwiftUI
import OrbitCore

/// Compact untimed chip for the Calendar Day list (user reference IMG_1210):
/// a calm tinted capsule with a small completion circle and a single-line
/// title. No repeated date label and no always-visible action icons — date
/// and time editing stay behind tap and the native context menu through the
/// existing callbacks and sheets. The visual capsule stays ~32pt; the
/// interactive row keeps a ≥44pt hit area without overlapping neighbours.
/// Accessibility sizes grow the capsule with Dynamic Type; the full source
/// title always stays in the accessibility label.
struct CompactCalendarTaskRow: View {
    let task: OrbitTask
    let model: IOSInboxModel
    let onEditDate: () -> Void
    let onEditInterval: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Button {
                model.setCompleted(!task.isCompleted, for: task)
            } label: {
                ZStack {
                    Circle()
                        .fill(task.isCompleted ? Color.orbitAccent : Color.clear)
                    Circle()
                        .strokeBorder(
                            task.isCompleted ? Color.orbitAccent : Color(.systemGray3),
                            lineWidth: 1.5
                        )
                    if task.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color.white)
                    }
                }
                .frame(width: 20, height: 20)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                task.isCompleted ? "Снова открыть: \(task.title)" : "Отметить выполненной: \(task.title)"
            )

            Button(action: onEditDate) {
                HStack(spacing: 0) {
                    Text(task.title)
                        .font(.subheadline)
                        .foregroundStyle(task.isCompleted ? Color.secondary : Color.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(
                        task.isCompleted ? Color(.tertiarySystemFill) : Color(.secondarySystemBackground)
                    )
                )
                .frame(maxWidth: .infinity, minHeight: 32)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(task.title)
            .accessibilityHint("Открывает редактор даты; контекстное меню — время и завершение")
        }
        .frame(minHeight: 44)
        .contextMenu {
            Button("Дата задачи…") { onEditDate() }
            Button("Время задачи…") { onEditInterval() }
            Button(task.isCompleted ? "Снова открыть" : "Завершить") {
                model.setCompleted(!task.isCompleted, for: task)
            }
        }
    }
}
