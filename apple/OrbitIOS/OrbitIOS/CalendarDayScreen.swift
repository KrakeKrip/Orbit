import SwiftUI
import OrbitCore

/// The «Календарь» day view: one selected civil day shown as a 00:00–24:00
/// timeline (via `TaskDayProjector`) with untimed tasks listed separately.
/// Read-only slice over the shared model — tap opens the existing interval
/// editor for the source task, context menu reuses existing complete/reopen
/// and date operations; creation stays in the Inbox composer.
struct CalendarDayScreen: View {
    let model: IOSInboxModel

    @State private var presentation: InboxSheetPresentation?
    @State private var selectedDay: String = TaskDaySelection.currentDay()
    @State private var pickerDate: Date = TaskPlannedDate.date(
        fromCivilDateString: TaskDaySelection.currentDay()
    ) ?? Date()
    @State private var untimedExpanded = false
    /// Measured height of the whole calendar content area (date controls +
    /// untimed region + timeline); the expanded untimed viewport derives from
    /// it instead of fixed screen math, so rotation and window changes adapt.
    @State private var contentHeight: CGFloat = 0
    /// Natural height of all untimed rows in the expanded region, measured
    /// after layout — keeps a short expanded list from becoming an empty area.
    @State private var expandedContentHeight: CGFloat?

    private let gregorianNoon: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar
    }()

    private static let rangeLowerBound = TaskPlannedDate.date(fromCivilDateString: "1900-01-01") ?? Date.distantPast
    private static let rangeUpperBound = TaskPlannedDate.date(fromCivilDateString: "2199-12-31") ?? Date.distantFuture

    private static let collapsedUntimedLimit = 3

    /// Rough height of one collapsed row (44pt controls + vertical padding).
    /// Only a sizing estimate for the expanded viewport floor; real rows
    /// always render at their natural, Dynamic-Type-aware height.
    private static let estimatedCompactRowHeight: CGFloat = 56
    /// Reserves subtracted from the measured content height before the
    /// expanded untimed viewport may take its ~⅓ share.
    private static let dayControlsReserve: CGFloat = 64
    private static let toggleReserve: CGFloat = 56
    private static let gridReserve: CGFloat = 220

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                dayControls
                if let writeError = model.writeError {
                    writeErrorBanner(writeError)
                }
                if model.listError != nil {
                    listErrorView
                } else {
                    untimedSection
                    DayTimelineView(
                        segments: projection.timedSegments,
                        task: { taskID in model.tasks.first { $0.id == taskID } },
                        onEditInterval: { task in presentation = .interval(task) },
                        onComplete: { task in model.setCompleted(true, for: task) },
                        onReopen: { task in model.setCompleted(false, for: task) },
                        onEditDate: { task in presentation = .date(task) }
                    )
                }
            }
            .navigationTitle("Календарь")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(.systemBackground))
            .background(
                // Adaptive sizing source: the real height of this content area
                // (safe areas applied), never fixed UIScreen values.
                GeometryReader { proxy in
                    Color.clear
                        .onAppear { contentHeight = proxy.size.height }
                        .onChange(of: proxy.size.height) { _, height in contentHeight = height }
                }
            )
            .sheet(item: $presentation) { item in
                switch item {
                case .date(let task):
                    TaskDateSheet(task: task, model: model)
                case .interval(let task):
                    TaskIntervalSheet(task: task, model: model)
                }
            }
            .onAppear {
                // Reactive model updates already refresh the rows; this reload
                // keeps the day view in sync after external changes. The
                // manually selected day is never reset here.
                model.reload()
            }
            .onChange(of: selectedDay) { _, _ in
                // Day switch collapses the untimed area and drops its scroll
                // state; the timeline subtree keeps its identity and offset.
                untimedExpanded = false
                expandedContentHeight = nil
            }
        }
    }

    // MARK: - Projection

    private var projection: TaskDayProjection {
        TaskDayProjector.project(day: selectedDay, in: model.tasks)
    }

    private func untimedTask(withID id: UUID) -> OrbitTask? {
        model.tasks.first { $0.id == id }
    }

    // MARK: - Day controls

    private var dayControls: some View {
        HStack(spacing: 12) {
            Button {
                if let candidate = shiftedDay(-1) { select(candidate) }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .medium))
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(shiftedDay(-1) == nil)
            .accessibilityLabel("Предыдущий день")

            DatePicker(
                "Дата",
                selection: $pickerDate,
                in: Self.rangeLowerBound...Self.rangeUpperBound,
                displayedComponents: [.date]
            )
            .labelsHidden()
            .onChange(of: pickerDate) { _, newDate in
                select(TaskPlannedDate.civilDateString(from: newDate, calendar: gregorianNoon))
            }

            Button {
                if let candidate = shiftedDay(1) { select(candidate) }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 17, weight: .medium))
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(shiftedDay(1) == nil)
            .accessibilityLabel("Следующий день")

            Spacer(minLength: 0)

            Button("Сегодня") {
                select(TaskDaySelection.currentDay())
            }
            .buttonStyle(.bordered)
            .tint(.orbitAccent)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.bar)
    }

    /// ±1 civil day anchored at noon, valid only inside 1900–2199.
    private func shiftedDay(_ delta: Int) -> String? {
        guard let anchor = TaskPlannedDate.date(
            fromCivilDateString: selectedDay,
            calendar: gregorianNoon
        ) else { return nil }
        guard let shifted = gregorianNoon.date(byAdding: .day, value: delta, to: anchor) else { return nil }
        let candidate = TaskPlannedDate.civilDateString(from: shifted, calendar: gregorianNoon)
        return TaskPlannedDate.isValid(candidate) ? candidate : nil
    }

    /// Guarded selection: an invalid candidate never changes the state.
    private func select(_ day: String) {
        guard TaskPlannedDate.isValid(day) else { return }
        selectedDay = day
        pickerDate = TaskPlannedDate.date(fromCivilDateString: day, calendar: gregorianNoon) ?? pickerDate
    }

    // MARK: - Untimed area (collapsible so many tasks never push the grid)

    /// Default collapsed: up to 3 untimed rows at their natural height — no
    /// ScrollView, no reserved empty rows, no blind clipping (multiline and
    /// Dynamic Type rows stay fully readable). «Ещё N» expands into a bounded,
    /// independently scrollable viewport capped near ⅓ of the measured content
    /// height; the toggle is a sibling below the rows, so its 44pt budget is
    /// laid out exactly once. Expanding/collapsing never writes, never
    /// recreates the timeline, and never resets the grid scroll position.
    private var untimedSection: some View {
        let ids = projection.untimedTaskIDs
        let overLimit = ids.count > Self.collapsedUntimedLimit

        return VStack(alignment: .leading, spacing: 0) {
            if ids.isEmpty {
                Text("Без времени — нет задач")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
            } else {
                Text("Без времени")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 6)

                if untimedExpanded {
                    expandedUntimedRegion(ids: ids)
                } else {
                    VStack(spacing: 0) {
                        ForEach(ids.prefix(Self.collapsedUntimedLimit), id: \.self) { id in
                            untimedRow(id)
                        }
                    }
                }

                if overLimit {
                    untimedToggleButton(count: ids.count)
                }
            }
            Divider()
        }
        .background(Color(.systemBackground))
    }

    private func untimedRow(_ id: UUID) -> some View {
        Group {
            if let task = untimedTask(withID: id) {
                InboxRowView(task: task, model: model) {
                    presentation = .date(task)
                } onEditInterval: {
                    presentation = .interval(task)
                }
            }
        }
    }

    /// Bounded expanded region: every untimed row of the day, scrolling
    /// internally only when they exceed the adaptive viewport (below).
    /// `.id(selectedDay)` gives this region alone a fresh scroll offset on a
    /// day switch; the timeline is a separate subtree and never remounts.
    private func expandedUntimedRegion(ids: [UUID]) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(ids, id: \.self) { id in
                    untimedRow(id)
                }
            }
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .onAppear { expandedContentHeight = proxy.size.height }
                        .onChange(of: proxy.size.height) { _, height in expandedContentHeight = height }
                }
            )
        }
        .id(selectedDay)
        .frame(height: min(expandedViewportCap, expandedContentHeight ?? expandedViewportCap))
    }

    private func untimedToggleButton(count: Int) -> some View {
        Button {
            untimedExpanded.toggle()
            if untimedExpanded {
                expandedContentHeight = nil
            }
        } label: {
            Label(
                untimedExpanded ? "Свернуть" : "Ещё \(count - Self.collapsedUntimedLimit)",
                systemImage: untimedExpanded ? "chevron.up" : "chevron.down"
            )
            .font(.footnote.weight(.medium))
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color.orbitAccent)
        .accessibilityIdentifier("untimed-toggle")
        .accessibilityLabel(
            untimedExpanded ? "Свернуть без времени" : "Ещё \(count - Self.collapsedUntimedLimit) без времени"
        )
    }

    /// Expanded viewport cap from the measured content height: target ~⅓ of
    /// it, at least enough for four compact rows on a normal iPhone, never
    /// more than what remains after the date controls, the toggle row and the
    /// grid reserve. Small windows or large Dynamic Type show fewer rows and
    /// scroll inside the region instead of losing the grid.
    private var expandedViewportCap: CGFloat {
        let toggle = projection.untimedTaskIDs.count > Self.collapsedUntimedLimit ? Self.toggleReserve : 0
        let remaining = contentHeight - Self.dayControlsReserve - toggle - Self.gridReserve
        let target = max(
            CGFloat(Self.collapsedUntimedLimit + 1) * Self.estimatedCompactRowHeight,
            contentHeight / 3
        )
        return max(0, min(target, remaining))
    }

    // MARK: - Errors

    private var listErrorView: some View {
        ContentUnavailableView {
            Label("Не удалось загрузить задачи", systemImage: "externaldrive.badge.exclamationmark")
        } description: {
            Text(model.listError ?? "")
        } actions: {
            Button("Повторить") { model.reload() }
                .buttonStyle(.borderedProminent)
                .tint(.orbitAccent)
        }
    }

    private func writeErrorBanner(_ message: String) -> some View {
        Text(message)
            .font(.footnote)
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemBackground))
            .accessibilityIdentifier("calendar-write-error")
    }
}
