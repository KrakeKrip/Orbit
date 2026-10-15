import SwiftUI
import OrbitCore

private struct ProjectEditorPresentation: Identifiable {
    let id = UUID()
    var projectID: UUID?
    var name = ""
}

/// Project metadata only: opening a row edits its name until task membership exists.
struct ProjectsScreen: View {
    let model: IOSInboxModel
    @Environment(\.orbitAppearance) private var appearance
    @State private var editor: ProjectEditorPresentation?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Text("Проекты").font(.title2.bold())
                    Spacer(minLength: 8)
                    Button {
                        OrbitHaptics.selection()
                        editor = ProjectEditorPresentation()
                    } label: {
                        Image(systemName: "plus").font(.system(size: 18, weight: .medium))
                            .frame(width: 28, height: 28)
                    }
                    .orbitIconStyle()
                    .accessibilityLabel("Создать проект")
                    .accessibilityIdentifier("project-create")
                    OrbitSettingsButton()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                if let error = model.projectListError {
                    ContentUnavailableView {
                        Label("Проекты недоступны", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(error)
                    } actions: {
                        Button("Повторить") { model.reloadProjects() }
                    }
                } else if model.projects.isEmpty {
                    ContentUnavailableView {
                        Label("Пока нет проектов", systemImage: "folder")
                    } description: {
                        Text("Создайте первый проект — например, «Работа» или «Личное».")
                    } actions: {
                        Button("Создать проект") { editor = ProjectEditorPresentation() }
                            .orbitPrimaryStyle()
                            .accessibilityIdentifier("project-create-empty")
                    }
                } else {
                    List {
                        ForEach(model.projects) { project in
                            Button {
                                editor = ProjectEditorPresentation(projectID: project.id, name: project.name)
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: "folder")
                                        .font(.title3).foregroundStyle(Color.orbitAccent)
                                    Text(project.name)
                                        .foregroundStyle(.primary)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Spacer(minLength: 8)
                                    Image(systemName: "pencil").foregroundStyle(.secondary)
                                }
                                .frame(minHeight: 44, alignment: .leading)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(project.name)
                            .accessibilityHint("Переименовать проект")
                            .accessibilityIdentifier("project-row-\(project.id.uuidString)")
                            .listRowBackground(appearance.canvas)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .refreshable { model.reloadProjects() }
                }
            }
            .background(appearance.canvas)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(item: $editor) { item in
                ProjectNameSheet(presentation: item, model: model)
            }
        }
        .onAppear { model.reloadProjects() }
    }
}

private struct ProjectNameSheet: View {
    let presentation: ProjectEditorPresentation
    let model: IOSInboxModel
    @Environment(\.dismiss) private var dismiss
    @State private var draft: String
    @State private var error: String?
    @FocusState private var nameFocused: Bool

    init(presentation: ProjectEditorPresentation, model: IOSInboxModel) {
        self.presentation = presentation
        self.model = model
        _draft = State(initialValue: presentation.name)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Например, Работа", text: $draft)
                        .textInputAutocapitalization(.sentences)
                        .submitLabel(.done)
                        .focused($nameFocused)
                        .onSubmit(save)
                        .accessibilityLabel("Название проекта")
                        .accessibilityIdentifier("project-name")
                } header: {
                    Text("Название")
                } footer: {
                    Text("До \(ProjectName.maximumLength) символов.")
                }
                if let error {
                    Section {
                        Text(error).foregroundStyle(.red)
                            .accessibilityIdentifier("project-editor-error")
                    }
                }
            }
            .orbitEditorSurface()
            .navigationTitle(presentation.projectID == nil ? "Новый проект" : "Проект")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить", action: save)
                        .accessibilityIdentifier("project-save")
                }
            }
        }
        .task { nameFocused = true }
    }

    private func save() {
        if let message = model.saveProject(name: draft, for: presentation.projectID) {
            error = message
        } else {
            OrbitHaptics.selection()
            dismiss()
        }
    }
}
