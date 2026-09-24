import SwiftUI

@main
@MainActor
struct MainApp: App {
    @StateObject var bluetoothManager = BluetoothManager()
    @StateObject var store = Store()

    init() {
        // Before any view can touch Settings.shared and write a settings key of its own.
        Settings.resolveEntitlementIfNeeded()
        // Before the first string is looked up. Read statically, like the call above, so
        // Settings (and its AVAudioEngine) is still not constructed at launch.
        Bundle.setLanguage(AppLanguage.fromTag(AppLanguage.saved))
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
