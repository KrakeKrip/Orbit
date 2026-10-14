import SwiftUI
import OrbitCore

/// NATIVE-ADD-002: the one shared creation UI for every section view. The
/// coral circular «+» floats at the bottom trailing edge above the native
/// tab bar (placed in the real bottom safe-area inset, never via
/// UIScreen/device coordinates) and presents the one create sheet. The date
/// preset is fixed by the host at the moment of opening — Inbox is always
/// undated, Today uses the fresh local Gregorian day, Upcoming uses its
/// existing selected day. No interval/date-wheel/task-detail/Projects here:
/// a created task is edited later through the accepted editors.
struct OrbitCreateButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(Color.white)
                .frame(width: 56, height: 56)
                .background(Circle().fill(Color.orbitAccent))
                // Modest depth only so the circle reads as floating over the
                // content; no custom tab bar, material or glass imitation.
                .shadow(color: .black.opacity(0.18), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Добавить задачу")
        .accessibilityIdentifier("create-task-fab")
    }
}

/// Identifiable presentation for the item-based sheet: every opening gets a
/// fresh identity, so the sheet's draft is always local to that opening and
/// is destroyed on close — cancel/swipe never creates or mutates anything.
private struct TaskCreateSheetPresentation: Identifiable {
    let id = UUID()
    /// The civil date fixed for this opening (`nil` = undated Inbox task).
    let datePreset: String?
}

private struct OrbitCreateHostModifier: ViewModifier {
    let model: IOSInboxModel
    /// Evaluated at tap time so the preset is the day at the moment of
    /// opening, never a value captured earlier by the host.
    let datePreset: () -> String?

    @State private var presentation: TaskCreateSheetPresentation?

    func body(content: Content) -> some View {
        content
            // The button lives in the bottom safe-area region: it always sits
            // just above the native tab bar on every device, the inset comes
            // from the real safe area, and modal sheets/keyboard (presented
            // over the whole screen) can never be overlapped by it.
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Color.clear
                    .frame(height: 0)
                    .overlay(alignment: .bottomTrailing) {
                        OrbitCreateButton {
                            presentation = TaskCreateSheetPresentation(datePreset: datePreset())
                        }
                        .padding(.trailing, 16)
                        .padding(.bottom, 16)
                    }
            }
            .sheet(item: $presentation) { item in
                TaskCreateSheet(model: model, datePreset: item.datePreset)
            }
    }
}

extension View {
    /// Hosts the shared «+» and create sheet over a section view. Applied
    /// once per section host (Inbox, Today workspace, Upcoming workspace) so
    /// the list and calendar presentations share the same composition.
    func orbitCreateAction(
        model: IOSInboxModel,
        datePreset: @escaping () -> String?
    ) -> some View {
        modifier(OrbitCreateHostModifier(model: model, datePreset: datePreset))
    }
}

/// The one create sheet: title field, the visible fixed date context («Без
/// даты» or the host's civil day), explicit «Добавить»/«Отмена» and keyboard
/// submit. Opening, cancelling and swiping never write; the title/store
/// error appears inside the form and keeps the draft for retry; the sheet
/// closes only after a confirmed successful save (a later read failure is
/// not turned back into a write error). The date is never edited here —
/// after creation the accepted editors own it.
struct TaskCreateSheet: View {
    let model: IOSInboxModel
    let datePreset: String?

    @Environment(\.dismiss) private var dismiss
    @FocusState private var titleFieldFocused: Bool
    @State private var title = ""
    @State private var errorMessage: String?
    /// Set only on confirmed success; a repeated submit in the same turn
    /// (double tap) can then never insert a duplicate.
    @State private var created = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextField("Название задачи", text: $title, prompt: Text("Название задачи"))
                    .focused($titleFieldFocused)
                    .submitLabel(.done)
                    .onSubmit(submit)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        Color(.secondarySystemBackground),
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                    )
                    .accessibilityIdentifier("create-title-field")

                Text(dateContextCaption)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("create-date-context")

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityIdentifier("create-error")
                }

                Button(action: submit) {
                    Text("Добавить")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orbitAccent)
                .disabled(isTitleBlank)
                .accessibilityIdentifier("create-add-button")

                Button("Отмена") { dismiss() }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier("create-cancel-button")

                Spacer(minLength: 0)
            }
            .padding(16)
            .navigationTitle("Новая задача")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { titleFieldFocused = true }
        }
        .presentationDetents([.medium, .large])
    }

    /// The fixed context of this opening, shown in Russian regardless of the
    /// device locale; the value itself is never editable here.
    private var dateContextCaption: String {
        guard let datePreset else { return "Без даты" }
        return "Дата: \(RussianDateCaption.label(datePreset))"
    }

    private var isTitleBlank: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func submit() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        // The «Добавить» button is disabled while blank; this guard covers the
        // keyboard submit path with the same refusal.
        guard !trimmedTitle.isEmpty else {
            errorMessage = "Введите название задачи."
            return
        }
        guard !created else { return }
        if let message = model.create(title: trimmedTitle, plannedDate: datePreset) {
            // The sheet and the draft stay up for retry; the list itself was
            // rolled back to persisted truth by the model.
            errorMessage = message
        } else {
            created = true
            dismiss()
        }
    }
}
