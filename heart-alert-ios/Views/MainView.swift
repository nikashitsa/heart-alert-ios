import SwiftUI

enum AppFlow {
    case connect
    case settings
    case tracking
}

struct MainView: View {
    @State private var flow: AppFlow = ScreenshotScene.current?.flow ?? .connect
    @StateObject private var settings = Settings.shared
    @EnvironmentObject private var bluetoothManager: BluetoothManager

    var body: some View {
        ZStack {
            // Keyed on the language too: a new pick redraws the screen in it, the same way
            // Android recreates the Activity, while `flow` keeps the user where they were.
            currentView()
                .id("\(flow)-\(settings.appLanguage.tag)")
                .transition(.opacity)
        }
        .animation(.easeInOut(duration: 0.2), value: flow)
        .environment(\.locale, settings.appLanguage.locale)
        .onAppear { ScreenshotScene.current?.apply(to: settings, bluetooth: bluetoothManager) }
    }
    
    @ViewBuilder
    private func currentView() -> some View {
        switch flow {
        case .connect:
            ConnectView(
                onConnected: {
                    withAnimation { flow = .settings }
                }
            )
        case .settings:
            SettingsView(
                onSuccess: {
                    withAnimation { flow = .tracking }
                }
            )
        case .tracking:
            TrackingView(
                onCancel: {
                    withAnimation { flow = .settings }
                }
            )
        }
    }
}

#Preview {
    MainView().environmentObject(BluetoothManager())
}

