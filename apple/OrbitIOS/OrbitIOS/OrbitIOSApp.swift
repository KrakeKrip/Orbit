import SwiftUI
import OrbitCore

@main
struct OrbitIOSApp: App {
    private enum Launch {
        case ready(IOSInboxModel)
        case openFailed(String)
    }

    private enum Tab: Hashable {
        case today
        case inbox
        case calendar
    }

    @Environment(\.scenePhase) private var scenePhase
    @State private var launch: Launch
    @State private var selectedTab: Tab = .today

    init() {
        _launch = State(initialValue: Self.openLaunchStore())
    }

    /// Opens the app's own sandbox store (explicit URL, no launch overrides).
    /// On failure shows an explicit error state and never deletes the store
    /// or falls back to an in-memory database.
    private static func openLaunchStore() -> Launch {
        do {
            let store = try IOSStore.open()
            return .ready(IOSInboxModel(store: store))
        } catch {
            return .openFailed(IOSInboxFormatting.openMessage(error))
        }
    }

    var body: some Scene {
        WindowGroup {
            switch launch {
            case .ready(let model):
                TabView(selection: $selectedTab) {
                    TodayScreen(model: model) {
                        selectedTab = .inbox
                    }
                    .tabItem {
                        Label("Сегодня", systemImage: "sun.max")
                    }
                    .tag(Tab.today)
                    InboxScreen(model: model)
                        .tabItem {
                            Label("Входящие", systemImage: "tray")
                        }
                        .tag(Tab.inbox)
                    CalendarDayScreen(model: model)
                        .tabItem {
                            Label("Календарь", systemImage: "calendar")
                        }
                        .tag(Tab.calendar)
                }
                .tint(.orbitAccent)
                .onChange(of: scenePhase) { _, phase in
                    // Returning to the foreground re-reads the shared store so
                    // all tabs reflect persisted truth.
                    if phase == .active {
                        model.reload()
                    }
                }
            case .openFailed(let message):
                StoreFailureView(message: message)
            }
        }
    }
}
