import SwiftUI
import PolarBleSdk

struct BpmPickerView: View {
    var range: ClosedRange<Int>
    var title: String
    @State var selectedBpm: Int
    
    var onConfirm: (Int) -> Void = {_ in }
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            Text(title).setFontStyle(Fonts.textLgBold)
            VStack {
                Picker("Devices", selection: $selectedBpm) {
                    ForEach(range, id: \.self) { bpm in
                        Text("\(bpm)")
                            .setFontStyle(Fonts.textMd)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .tag(bpm)
                    }
                }
                .pickerStyle(.wheel)
            }.frame(maxHeight: .infinity)
            Button(action: choose) {
                Text("Confirm").setFontStyle(Fonts.textMdBold)
            }.buttonStyle(PrimaryButton())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private func choose() {
        onConfirm(selectedBpm)
        dismiss()
    }
}
