import SwiftUI

struct ConnectView: View {
    var onConnected: () -> Void = {}
    
    @EnvironmentObject private var bluetoothManager: BluetoothManager
    @State private var showPicker = false
    @State private var opacity = 1.0
    
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
                    Text("Heart Alert").setFontStyle(Fonts.textXlBold)
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
}

#Preview {
    ConnectView().environmentObject(BluetoothManager())
}
