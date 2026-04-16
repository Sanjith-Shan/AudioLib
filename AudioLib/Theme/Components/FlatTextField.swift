import SwiftUI

/// A text field with surface background, pill shape, no shadow. Used for URL input.
struct FlatTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        TextField(placeholder, text: $text)
            .font(.bodyRegular)
            .foregroundStyle(Theme.Colors.dark)
            .keyboardType(keyboardType)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .padding(.vertical, Theme.Spacing.sm + Theme.Spacing.xs)
            .padding(.horizontal, Theme.Spacing.md)
            .background(Theme.Colors.surface)
            .clipShape(Capsule())
    }
}

#Preview {
    @Previewable @State var text = ""
    FlatTextField(placeholder: "Paste YouTube URL", text: $text, keyboardType: .URL)
        .padding()
}
