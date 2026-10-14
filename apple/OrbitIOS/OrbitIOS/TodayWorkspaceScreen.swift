import Combine
import SwiftUI
import OrbitCore

/// The «Сегодня» section (NATIVE-NAV-001): one shared model/store with two
/// switchable presentations — the accepted large-row list (`TodayScreen`)
/// and the accepted day calendar (`CalendarDayScreen` in its fixed-day
/// context). This view is the single current-day owner: the local Gregorian
/// day is recomputed on appear, on scene activation and at least once a
/// minute while the section is visible, and both presentations receive it as
/// input. The chosen mode is presentation state only — it survives
/// Today → Inbox → Today within the session and never writes tasks.
struct TodayWorkspaceScreen: View {
    let model: IOSInboxModel
    let onGoToInbox: () -> Void

    @Environment(\.scenePhase) private var scenePhase
    @State private var showsCalendar = false
    @State private var currentDay: String = TaskDaySelection.currentDay()
    private let dayRefreshTimer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        Group {
            if showsCalendar {
                CalendarDayScreen(model: model, fixedDay: currentDay, todayMode: $showsCalendar)
            } else {
                TodayScreen(model: model, day: currentDay, onGoToInbox: onGoToInbox, todayMode: $showsCalendar)
            }
        }
        .onAppear { refreshDay() }
        .onReceive(dayRefreshTimer) { _ in refreshDay(reloadTasks: false) }
        .onChange(of: currentDay) { _, _ in model.reload() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                refreshDay()
            }
        }
    }

    /// Recomputes the current local day; reloads the shared model on explicit
    /// refreshes (appear, scene activation) or when the day changed, so both
    /// presentations follow midnight/timezone changes together.
    private func refreshDay(reloadTasks: Bool = true) {
        let newDay = TaskDaySelection.currentDay()
        let dayChanged = newDay != currentDay
        currentDay = newDay
        if reloadTasks || dayChanged {
            model.reload()
        }
    }
}

/// Compact «Список / Календарь» mode switcher for the Today section:
/// segmented native control with an obvious selected state. Presentation
/// state only — switching never clones, migrates or creates tasks.
struct TodayModeSwitcher: View {
    @Binding var showsCalendar: Bool

    var body: some View {
        Picker("Вид", selection: $showsCalendar) {
            Text("Список").tag(false)
            Text("Календарь").tag(true)
        }
        .pickerStyle(.segmented)
        .fixedSize()
        .frame(minHeight: 44)
        .accessibilityIdentifier("today-mode-switcher")
    }
}
