import SwiftUI

/// NATIVE-UI-MODE: the one common «Список / Календарь» mode row composition
/// for the Today and Upcoming sections, shared by their list and calendar
/// presentations alike. The switcher control itself stays the section's
/// existing segmented `TodayModeSwitcher`/`UpcomingModeSwitcher` (one
/// definition per section, no duplicated `Picker`); `NativeModeHeader` hosts
/// it leading in the same top row — same insets, height and `.bar` band as
/// the calendar date controls, directly under the navigation bar — so
/// switching a section's view never moves or restyles the control and no
/// toolbar item wraps it into a second contour. The trailing content (none
/// in the list screens) never shifts the switcher: it is fixed-size and the
/// spacer absorbs the slack, so a row without trailing content keeps the
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
