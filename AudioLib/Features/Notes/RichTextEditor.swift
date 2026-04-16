import SwiftUI
import UIKit

struct RichTextEditor: UIViewRepresentable {
    @Binding var attributedText: NSAttributedString
    var placeholder: String = "Start writing..."

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.allowsEditingTextAttributes = true
        textView.isScrollEnabled = true
        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)

        // Default font
        textView.typingAttributes = [
            .font: UIFont(name: "Inter-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16),
            .foregroundColor: UIColor(Theme.Colors.dark)
        ]

        // Attach formatting toolbar
        let toolbar = FormattingToolbar(textView: textView)
        textView.inputAccessoryView = toolbar

        if attributedText.length > 0 {
            textView.attributedText = attributedText
        }

        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        // Only update if changed from outside (not from user typing)
        if textView.attributedText != attributedText && !context.coordinator.isEditing {
            textView.attributedText = attributedText.length > 0 ? attributedText : NSAttributedString()
        }
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: RichTextEditor
        var isEditing = false

        init(_ parent: RichTextEditor) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.attributedText = textView.attributedText
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            isEditing = true
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            isEditing = false
        }
    }
}
