import SwiftUI

@main
struct MainApp: App {
    @StateObject var bluetoothManager = BluetoothManager()
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .preferredColorScheme(ColorScheme.dark)
                .environmentObject(bluetoothManager)
        }
    }
}
