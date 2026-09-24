import SwiftUI

/// Pill with a globe and the current language's code; opens a menu of all languages.
/// `selection` is the saved tag, nil while the app follows the device language.
struct LanguagePickerView: View {
    @Binding var selection: String?

    private var language: Binding<AppLanguage> {
        Binding(
            get: { AppLanguage.resolve(saved: selection) },
            set: { if $0 != AppLanguage.resolve(saved: selection) { selection = $0.tag } }
        )
    }

    var body: some View {
        Menu {
            Picker("Language", selection: language) {
                ForEach(AppLanguage.sorted) { language in
                    Text(language.displayName).tag(language)
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "globe")
                    .font(.system(size: 16))
                    .accessibilityLabel(Text("Language"))
                Text(language.wrappedValue.code).setFontStyle(Fonts.textMd)
            }
            .padding(.horizontal, 14)
            .frame(height: 36)
            .background(Colors.gray)
            .clipShape(.capsule)
            .foregroundColor(Colors.white)
        }
    }
}

#Preview {
    LanguagePickerView(selection: .constant(nil))
}
