import SwiftUI

struct IntervalPickerView: View {
    var options: [Int]
    var labels: [Int: String] = [:]
    var title: String
    @State var selectedInterval: Int

    var onConfirm: (Int) -> Void = {_ in }

    @Environment(\.dismiss) private var dismiss

    static func label(_ seconds: Int, _ labels: [Int: String] = [:]) -> String {
        if let label = labels[seconds] {
            return label
        }
        if seconds > 0 && seconds % 60 == 0 {
            return "\(seconds / 60) min"
        }
        return "\(seconds) sec"
    }

    var body: some View {
        VStack {
            Text(title).setFontStyle(Fonts.textLgBold)
            VStack {
                Picker("Interval", selection: $selectedInterval) {
                    ForEach(options, id: \.self) { interval in
                        Text(Self.label(interval, labels))
                            .setFontStyle(Fonts.textMd)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .tag(interval)
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
        onConfirm(selectedInterval)
        dismiss()
    }
}
