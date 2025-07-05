import SwiftUI

enum AppFlow {
    case connect
    case settings
    case tracking
}

struct MainView: View {
    @State private var flow: AppFlow = .connect
    
    var body: some View {
        ZStack {
            currentView()
                .id(flow)
                .transition(.opacity)
        }.animation(.easeInOut(duration: 0.2), value: flow)
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
    MainView()
}

