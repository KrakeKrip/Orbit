import SwiftUI

/// NATIVE-UI-MODE/R1: the one common «Список / Календарь» mode row
/// composition, hosted as the first row directly under the safe area by all
/// four leaf presentations (Today/Upcoming × list/calendar — no navigation
/// title or bar above it on any of them, so the control keeps its physical
/// position when a section switches views). The switcher control itself
/// stays the section's existing segmented `TodayModeSwitcher`/
/// `UpcomingModeSwitcher` (one definition per section, no duplicated
/// `Picker`); `NativeModeHeader` hosts it leading with the same insets,
/// height and `.bar` band everywhere. The trailing content (calendar «⋯»
/// menu, fixed-day caption) never shifts the switcher: it is fixed-size and
/// the spacer absorbs the slack, so a row without trailing content keeps the
/// control in the same leading position as the calendar rows.
struct NativeModeHeader<Switcher: View, Trailing: View>: View {
    private let switcher: Switcher
    private let trailing: Trailing

    init(switcher: Switcher, @ViewBuilder trailing: () -> Trailing) {
        self.switcher = switcher
        self.trailing = trailing()
    }

    var body: some View {
        HStack(spacing: 8) {
            switcher
            Spacer(minLength: 8)
            trailing
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(.bar)
    }
}

extension NativeModeHeader where Trailing == EmptyView {
    /// The list presentations have no trailing control on the mode row.
    init(switcher: Switcher) {
        self.init(switcher: switcher, trailing: { EmptyView() })
    }
}
