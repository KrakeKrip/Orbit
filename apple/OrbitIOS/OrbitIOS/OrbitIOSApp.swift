import SwiftUI
import OrbitCore

@main
struct OrbitIOSApp: App {
    private enum Launch {
        case ready(IOSInboxModel)
        case openFailed(String)
    }

    @State private var launch: Launch

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
                InboxScreen(model: model)
            case .openFailed(let message):
                StoreFailureView(message: message)
            }
        }
    }
}
