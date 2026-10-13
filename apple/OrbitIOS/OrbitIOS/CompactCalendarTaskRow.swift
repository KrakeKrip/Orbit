import SwiftUI
import OrbitCore

/// Compact untimed chip for the Calendar Day list (user reference IMG_1210):
/// one calm tinted capsule that holds the small completion circle (left of
/// the title) and the single-line title together. No repeated date label and
/// no always-visible action icons — date and time editing stay behind the
/// title tap and the native context menu through the existing callbacks and
/// sheets. The visual capsule stays ~34pt inside the ≥44pt interaction row;
/// the circle keeps its own 44×44 hit region within the row, so a title or
/// card tap never completes a task by accident. Accessibility sizes grow the
/// row and the capsule together with Dynamic Type; the full source title
/// always stays in the accessibility label.
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
                // Own 44×44 hit region inside the shared capsule's row; it
                // never extends into the title's area.
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                task.isCompleted ? "Снова открыть: \(task.title)" : "Отметить выполненной: \(task.title)"
            )

            Button(action: onEditDate) {
                Text(task.title)
                    .font(.subheadline)
                    .foregroundStyle(task.isCompleted ? Color.secondary : Color.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    .padding(.trailing, 16)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(task.title)
            .accessibilityHint("Открывает редактор даты; контекстное меню — время и завершение")
        }
        // One shared capsule behind circle and title; the 5pt vertical inset
        // keeps the visual capsule ~34pt inside the ≥44pt hit row and grows
        // with Dynamic Type.
        .background(
            Capsule().fill(
                task.isCompleted ? Color(.tertiarySystemFill) : Color(.secondarySystemBackground)
            )
            .padding(.vertical, 5)
        )
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
