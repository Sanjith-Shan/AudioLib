import SwiftUI

/// A text field with a soft inset background, used for search / generic input.
struct FlatTextField: View {
    let placeholder: String
    @Binding var text: String
    #if os(iOS)
    var keyboardType: UIKeyboardType = .default
    #endif

    var body: some View {
        TextField(placeholder, text: $text)
            .font(.bodyRegular)
            .foregroundStyle(Theme.Colors.ink)
            #if os(iOS)
            .keyboardType(keyboardType)
            .textInputAutocapitalization(.never)
            #endif
            .autocorrectionDisabled()
            .padding(.vertical, Theme.Spacing.sm + Theme.Spacing.xs)
            .padding(.horizontal, Theme.Spacing.md)
            .background(Theme.Colors.cardSoft)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.field, style: .continuous))
    }
}
