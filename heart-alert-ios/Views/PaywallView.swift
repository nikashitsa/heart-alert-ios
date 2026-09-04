import SwiftUI

/// Tracking starts from the presenter's `onDismiss`, so both Continue and a swipe-away lead to
/// the same place.
struct PaywallView: View {
    @EnvironmentObject private var store: Store
    @StateObject private var settings = Settings.shared

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            // Read on every update rather than seeded into state: the sheet has to flip to
            // Success the moment the purchase lands, which may be while the user is watching.
            if settings.unlimitedAccess {
                paywallBody(
                    title: "Success",
                    description: "Unlimited access is now available."
                )
                Button(action: { dismiss() }) {
                    Text("Continue").setFontStyle(Fonts.textMdBold)
                }.buttonStyle(PrimaryButton())
            } else {
                paywallBody(
                    title: "Unlimited access",
                    description: "Your free sessions are complete.\nKeep monitoring with unlimited access."
                )
                if store.busy {
                    ProgressView().frame(height: 104)
                } else {
                    Button(action: {
                        Task { await store.purchase() }
                    }) {
                        Text("One-time purchase \(store.displayPrice)").setFontStyle(Fonts.textMdBold)
                    }.buttonStyle(PrimaryButton())
                    Button(action: {
                        Task { await store.restore() }
                    }) {
                        Text("Restore purchase").setFontStyle(Fonts.textMdBold)
                    }.buttonStyle(LinkButton())
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    /// Title plus copy, filling the space above the buttons.
    private func paywallBody(title: String, description: String) -> some View {
        Group {
            Text(title).setFontStyle(Fonts.textLgBold)
            VStack(spacing: 12) {
                Text(description).setFontStyleMultiline(Fonts.textMd)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let notice = store.notice {
                    Text(notice)
                        .setFontStyleMultiline(Fonts.textMd)
                        .foregroundColor(Colors.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    PaywallView().environmentObject(Store())
}
