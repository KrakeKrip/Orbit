import SwiftUI
import OrbitCore

/// The «Предстоящее» section (NATIVE-NAV-002): one shared model/store with
/// two switchable presentations over an independently selected civil day —
/// the large-row list (`UpcomingListScreen`, an inclusive 7-day window from
/// the selected day) and the accepted day calendar (`CalendarDayScreen` in
/// its browsing context). This view is the single Upcoming selection owner:
/// the selected day starts at the local Gregorian today and the mode at
/// «Список»; both survive tab and mode switches within the session as
/// presentation state — never persisted into tasks/store/UserDefaults — and
/// stay independent of the Today section's current day and mode.
/// Appear/active reloads of the shared model never reset the manual
/// selection.
struct UpcomingWorkspaceScreen: View {
    let model: IOSInboxModel

    @State private var showsCalendar = false
    @State private var selectedDay: String = TaskDaySelection.currentDay()

    var body: some View {
        Group {
            if showsCalendar {
                CalendarDayScreen(
                    model: model,
                    todayMode: $showsCalendar,
                    browsingDay: $selectedDay
                )
            } else {
                UpcomingListScreen(
                    model: model,
                    selectedDay: $selectedDay,
                    showsCalendar: $showsCalendar
                )
            }
        }
        .onAppear {
            // Keep the rows in sync after external changes; the selected day
            // and the mode are presentation state and are never reset here.
            model.reload()
        }
    }
}

/// Compact «Список / Календарь» mode switcher for the Upcoming section —
/// the same segmented native control as Today's, with its own accessibility
/// identifier so the two sections' independent modes stay distinguishable.
/// Presentation state only — switching never clones, migrates or creates
/// tasks.
struct UpcomingModeSwitcher: View {
    @Binding var showsCalendar: Bool

    var body: some View {
        Picker("Вид", selection: $showsCalendar) {
            Text("Список").tag(false)
            Text("Календарь").tag(true)
        }
        .pickerStyle(.segmented)
        .fixedSize()
        .frame(minHeight: 44)
        .accessibilityIdentifier("upcoming-mode-switcher")
    }
}
