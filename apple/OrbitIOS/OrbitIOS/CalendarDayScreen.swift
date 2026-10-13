import SwiftUI
import OrbitCore

/// The «Календарь» day view: one selected civil day shown as a 00:00–24:00
/// timeline (via `TaskDayProjector`) with untimed compact chips listed
/// separately (user reference IMG_1210 — no large navigation title, the
/// compact date controls sit directly under the safe area, the native «⋯»
/// menu next to them holds «Задачи дня» — the timed segments of the day).
/// Read-only slice over the shared model — taps and the context menu reuse
/// the existing complete/reopen and date/interval editors for the source
/// task; creation stays in the Inbox composer.
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

    /// Rough height of one compact untimed card (≈26pt visual rounded
    /// rectangle) plus the 2pt group gap. Only a sizing estimate for the
    /// expanded viewport floor; real rows always render at their natural,
    /// Dynamic-Type-aware height.
    private static let estimatedCompactRowHeight: CGFloat = 28
    /// Left gutter of the untimed area, equal to the timeline's hour-ruler
    /// inset (DayTimelineView lane inset): the paired-chevrons expand toggle
    /// lives in this gutter and the card column's left edge lines up with
    /// the grid task area (user reference IMG_1218/IMG_1219).
    private static let untimedGridLeading: CGFloat = 56
    /// Reserves subtracted from the measured content height before the
    /// expanded untimed viewport may take its ~⅓ share. The date controls
    /// reserve covers the adaptive header: one 44pt row where it fits, or
    /// two rows («Сегодня» + «⋯» move down) on narrow widths. The gutter
    /// toggle adds no vertical budget — it sits beside the cards.
    private static let dayControlsReserve: CGFloat = 104
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

    private func task(withID id: UUID) -> OrbitTask? {
        model.tasks.first { $0.id == id }
    }

    // MARK: - Day controls

    /// Compact header right under the safe area. At accessibility text sizes
    /// the single row no longer fits the screen width; `ViewThatFits` then
    /// moves «Сегодня» to its own line so nothing overflows and shifts the
    /// rest of the content sideways.
    private var dayControls: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                prevDayButton
                datePickerField
                nextDayButton
                Spacer(minLength: 0)
                todayButton
                calendarMenu
            }
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 8) {
                    prevDayButton
                    datePickerField
                    nextDayButton
                }
                HStack {
                    todayButton
                    Spacer(minLength: 0)
                    calendarMenu
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(.bar)
    }

    private var prevDayButton: some View {
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
    }

    private var nextDayButton: some View {
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
    }

    private var datePickerField: some View {
        DatePicker(
            "Дата",
            selection: $pickerDate,
            in: Self.rangeLowerBound...Self.rangeUpperBound,
            displayedComponents: [.date]
        )
        .labelsHidden()
        // View-local Russian date only for this control («14 окт. 2026 г.»
        // instead of «Oct»); the device/system locale is never changed.
        .environment(\.locale, Locale(identifier: "ru_RU"))
        .onChange(of: pickerDate) { _, newDate in
            select(TaskPlannedDate.civilDateString(from: newDate, calendar: gregorianNoon))
        }
    }

    private var todayButton: some View {
        Button("Сегодня") {
            select(TaskDaySelection.currentDay())
        }
        .buttonStyle(.bordered)
        .tint(.orbitAccent)
    }

    /// Native «⋯» menu next to the date controls. The standalone timed panel
    /// above the grid is gone; this menu is the one compact accessible path
    /// to every timed segment of the selected day («Задачи дня»), including
    /// tiny/dense stripes, through the existing editors and completion
    /// callbacks. With no timed segments it shows an honest disabled line —
    /// never a fake action.
    private var calendarMenu: some View {
        Menu {
            if projection.timedSegments.isEmpty {
                Button("Нет задач с временем") {}
                    .disabled(true)
            } else {
                Menu("Задачи дня") {
                    ForEach(projection.timedSegments, id: \.taskID) { segment in
                        if let timed = task(withID: segment.taskID) {
                            Menu(dayTaskMenuTitle(segment)) {
                                Button("Редактировать время…") { presentation = .interval(timed) }
                                Button("Дата задачи…") { presentation = .date(timed) }
                                Button(timed.isCompleted ? "Снова открыть" : "Завершить") {
                                    model.setCompleted(!timed.isCompleted, for: timed)
                                }
                            }
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "ellipsis")
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .accessibilityLabel("Меню календаря")
        .accessibilityIdentifier("calendar-day-menu")
    }

    /// Full source title plus the selected-day range with continuation cues
    /// («↑»/«↓» at day edges) — the same data the grid block label shows.
    private func dayTaskMenuTitle(_ segment: TaskDayIntervalSegment) -> String {
        guard let timed = task(withID: segment.taskID) else { return "Задача" }
        let endTime = segment.endMinute == 1440 ? "24:00" : clockString(segment.endMinute)
        var range = "\(clockString(segment.startMinute))–\(endTime)"
        if segment.continuesFromPreviousDay { range += " ↑" }
        if segment.continuesIntoNextDay { range += " ↓" }
        return "\(timed.title) · \(range)"
    }

    private func clockString(_ minute: Int) -> String {
        String(format: "%02d:%02d", minute / 60, minute % 60)
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

    // MARK: - Untimed area (compact chips, collapsible so many tasks never
    // push the grid)

    /// Default collapsed: up to 3 compact untimed cards in one tight group
    /// (2pt gaps), left edge aligned with the grid task area. The expand
    /// toggle is the small paired-chevrons button in the left gutter above
    /// the hour-ruler column (reference IMG_1219) — no standalone button
    /// row under the cards; «Ещё N» is a small secondary caption under the
    /// card group at its left edge. Toggle and caption appear only when
    /// there are more than 3 tasks. Expanding shows a bounded, independently
    /// scrollable viewport capped near ⅓ of the measured content height;
    /// expanding/collapsing never writes, never recreates the timeline, and
    /// never resets the grid scroll position.
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

                HStack(alignment: .top, spacing: 0) {
                    Group {
                        if overLimit {
                            untimedToggleButton(count: ids.count)
                        } else {
                            // Empty gutter placeholder: fixed zero height, so
                            // it never claims surplus vertical space at ≤3
                            // tasks (the column width stays for alignment).
                            Color.clear
                                .frame(height: 0)
                        }
                    }
                    .frame(width: Self.untimedGridLeading)

                    Group {
                        if untimedExpanded {
                            expandedUntimedRegion(ids: ids)
                        } else {
                            VStack(spacing: 2) {
                                ForEach(ids.prefix(Self.collapsedUntimedLimit), id: \.self) { id in
                                    untimedRow(id)
                                }
                            }
                        }
                    }
                    .padding(.trailing, 16)
                }

                if overLimit && !untimedExpanded {
                    Text("Ещё \(ids.count - Self.collapsedUntimedLimit)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, Self.untimedGridLeading)
                        .padding(.top, 2)
                }
            }
            Divider()
        }
        .background(Color(.systemBackground))
    }

    private func untimedRow(_ id: UUID) -> some View {
        Group {
            if let task = task(withID: id) {
                CompactCalendarTaskRow(task: task, model: model) {
                    presentation = .date(task)
                } onEditInterval: {
                    presentation = .interval(task)
                }
            }
        }
    }

    /// Bounded expanded region: every untimed chip of the day, scrolling
    /// internally only when they exceed the adaptive viewport (below).
    /// `.id(selectedDay)` gives this region alone a fresh scroll offset on a
    /// day switch; the timeline is a separate subtree and never remounts.
    private func expandedUntimedRegion(ids: [UUID]) -> some View {
        ScrollView {
            VStack(spacing: 2) {
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

    /// Paired-chevrons expand/collapse toggle in the left gutter (reference
    /// IMG_1219): one small native button above the hour-ruler column,
    /// beside the first rows. The two chevrons are separate SF images whose
    /// directions swap with the state — collapsed upper-up/lower-down,
    /// expanded upper-down/lower-up — without whole-pair rotation (the
    /// combined `chevron.up.chevron.down` glyph is symmetric and would look
    /// unchanged). Its 44×44 hit sits fully inside the gutter column and
    /// never overlaps the card hit regions to its right; state never writes.
    private func untimedToggleButton(count: Int) -> some View {
        Button {
            untimedExpanded.toggle()
            if untimedExpanded {
                expandedContentHeight = nil
            }
        } label: {
            VStack(spacing: 2) {
                Image(systemName: untimedExpanded ? "chevron.down" : "chevron.up")
                Image(systemName: untimedExpanded ? "chevron.up" : "chevron.down")
            }
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(Color.orbitAccent)
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("untimed-toggle")
        .accessibilityLabel(
            untimedExpanded ? "Свернуть без времени" : "Показать ещё \(count - Self.collapsedUntimedLimit) без времени"
        )
    }

    /// Expanded viewport cap from the measured content height: target ~⅓ of
    /// it, at least enough for four compact rows on a normal iPhone, never
    /// more than what remains after the date controls and the grid reserve.
    /// Small windows or large Dynamic Type show fewer rows and scroll
    /// inside the region instead of losing the grid.
    private var expandedViewportCap: CGFloat {
        let remaining = contentHeight - Self.dayControlsReserve - Self.gridReserve
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
