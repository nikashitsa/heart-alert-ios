import SwiftUI

@main
@MainActor
struct MainApp: App {
    @StateObject var bluetoothManager = BluetoothManager()
    @StateObject var store = Store()

    init() {
        // Before any view can touch Settings.shared and write a settings key of its own.
        Settings.resolveEntitlementIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            MainView()
                .preferredColorScheme(ColorScheme.dark)
                .environmentObject(bluetoothManager)
                .environmentObject(store)
        }
    }
}
