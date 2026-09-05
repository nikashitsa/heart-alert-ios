import SwiftUI

struct ConnectView: View {
    var onConnected: () -> Void = {}
    
    @EnvironmentObject private var bluetoothManager: BluetoothManager
    @StateObject private var settings = Settings.shared
    @State private var showPicker = false
    @State private var opacity = 1.0

    // Demo mode unlock, for App Review. Disclosed in the App Review Notes, not secret.
    @State private var demoTaps = 0
    @State private var lastDemoTap = Date.distantPast
    private let demoTapsRequired = 7

    var body: some View {
        ZStack {
            Colors.black.ignoresSafeArea()
            VStack {
                VStack(spacing: 20) {
                    Spacer()
                    Image("Heart")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100.0)
                        .onTapGesture { countDemoTap() }
                    Text("Heart Alert").setFontStyle(Fonts.textXlBold)
                    if settings.demoMode {
                        Text("Demo mode").setFontStyle(Fonts.textMd)
                    }
                    Spacer()
                }
                Button(action: {
                    showPicker = true
                    withAnimation {
                        opacity = 0.0
                    }
                }) {
                    Text("Connect").setFontStyle(Fonts.textMdBold)
                }.buttonStyle(PrimaryButton())
                .padding()
                .sheet(
                    isPresented: $showPicker,
                    onDismiss: {
                        if case .connected = bluetoothManager.deviceConnectionState {
                            onConnected()
                        } else {
                            withAnimation {
                                opacity = 1.0
                            }
                        }
                    }
                ) {
                    DevicePickerView()
                        .presentationDetents([.medium])
                }
            }
            .opacity(opacity)
            .foregroundColor(Colors.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    /// Arms demo mode after seven taps on the logo, each within two seconds of the last, so
    /// stumbling on it by accident is implausible. Latches on: every demo path keys off the
    /// fake device's address rather than this flag, but leaving no way to switch it off keeps
    /// a live demo connection from ever being stranded. Re-arming clears the shadow
    /// entitlement, which is what lets the paywall be tested more than once.
    private func countDemoTap() {
        let now = Date()
        demoTaps = now.timeIntervalSince(lastDemoTap) < 2 ? demoTaps + 1 : 1
        lastDemoTap = now
        guard demoTaps >= demoTapsRequired else { return }
        demoTaps = 0
        settings.demoMode = true
        settings.demoUnlocked = false
    }
}

#Preview {
    ConnectView().environmentObject(BluetoothManager())
}
