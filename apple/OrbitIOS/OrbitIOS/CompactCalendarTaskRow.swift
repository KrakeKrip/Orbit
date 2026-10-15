import SwiftUI
import OrbitCore

/// Compact untimed card for the Calendar Day list (user reference IMG_1218):
/// a short tinted rounded rectangle (~26pt, corner radius 7) that holds the
/// small completion circle (12–14pt, left of the title) and a single-line
/// ~15pt title. No repeated date label and no always-visible action icons —
/// date and time editing stay behind the title tap and the native context
/// menu through the existing callbacks and sheets. Height is content-derived
/// (no flexible spacers); neighbouring hit regions stay inside their own
/// rows and never overlap. Accessibility sizes grow the card with Dynamic
/// Type; the full source title always stays in the accessibility label.
struct CompactCalendarTaskRow: View {
    let task: OrbitTask
    let model: IOSInboxModel
    let onEditDate: () -> Void
    let onEditInterval: () -> Void
    let onRename: () -> Void
    let onDelete: () -> Void

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
                            lineWidth: 1.25
                        )
                    if task.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundStyle(Color.white)
                    }
                }
                .frame(width: 13, height: 13)
                // Hit cell matches the card height; it stays inside this
                // leading column and never reaches the title's area.
                .padding(.horizontal, 6.5)
                .padding(.vertical, 6.5)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                task.isCompleted ? "Снова открыть: \(task.title)" : "Отметить выполненной: \(task.title)"
            )

            Menu {
                menuActions
            } label: {
                Text(task.title)
                    .font(.subheadline)
                    .foregroundStyle(task.isCompleted ? Color.secondary : Color.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding(.vertical, 3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.trailing, 12)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(task.title)
            .accessibilityHint("Открывает меню задачи")
            .orbitMenuFeedback()
        }
        .background(
            RoundedRectangle(cornerRadius: 7).fill(
                task.isCompleted ? Color(.tertiarySystemFill) : Color(.secondarySystemBackground)
            )
        )
        .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: 7))
        .orbitLongPressFeedback()
        .contextMenu { menuActions }
    }

    private var menuActions: some View {
        OrbitTaskMenuActions(
            task: task,
            onToggle: { model.setCompleted(!task.isCompleted, for: task) },
            onEditDate: onEditDate, onEditInterval: onEditInterval,
            onRename: onRename, onDelete: onDelete
        )
    }
}
