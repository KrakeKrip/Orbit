import SwiftUI
import OrbitCore

@main
struct OrbitMacApp: App {
    private enum Launch {
        case ready(InboxModel)
        case openFailed(String)
    }

    @State private var launch: Launch

    init() {
        _launch = State(initialValue: Self.openLaunchStore())
    }

    /// Opens the launch store; on failure shows an explicit error state and never
    /// deletes the store or falls back to an in-memory database.
    private static func openLaunchStore() -> Launch {
        let storeURL = OrbitStoreLocation.resolveStoreURL(commandLineArguments: CommandLine.arguments)
        do {
            let directory = storeURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let store = try OrbitTaskStore(storeURL: storeURL)
            return .ready(InboxModel(store: store))
        } catch {
            return .openFailed(InboxFormatting.openMessage(error))
        }
    }

    var body: some Scene {
        WindowGroup("Orbit") {
            switch launch {
            case .ready(let model):
                InboxView(model: model)
            case .openFailed(let message):
                StoreFailureView(message: message)
            }
        }
        .defaultSize(width: 560, height: 680)
    }
}

struct StoreFailureView: View {
    let message: String

    var body: some View {
        ContentUnavailableView {
            Label("Хранилище недоступно", systemImage: "externaldrive.badge.exclamationmark")
        } description: {
            Text(message)
        }
        .frame(minWidth: 460, minHeight: 300)
        .accessibilityIdentifier("store-failure")
    }
}
