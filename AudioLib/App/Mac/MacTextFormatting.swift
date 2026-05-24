#if os(macOS)
import AppKit

/// Routes formatting-toolbar commands to whichever NSTextView is first
/// responder (the note editor's text view).
enum MacTextFormatting {
    private static var textView: NSTextView? {
        NSApp.keyWindow?.firstResponder as? NSTextView
    }

    static func toggleTrait(_ trait: NSFontTraitMask) {
        guard let tv = textView else { return }
        let fm = NSFontManager.shared
        let range = tv.selectedRange()
        guard range.length > 0, let storage = tv.textStorage else {
            if let f = tv.typingAttributes[.font] as? NSFont {
                tv.typingAttributes[.font] = fm.convert(f, toHaveTrait: trait)
            }
            return
        }
        storage.enumerateAttribute(.font, in: range) { value, sub, _ in
            let base = (value as? NSFont) ?? NSFont.systemFont(ofSize: 16)
            storage.addAttribute(.font, value: fm.convert(base, toHaveTrait: trait), range: sub)
        }
        tv.didChangeText()
    }

    static func toggleUnderline() {
        textView?.underline(nil)
    }

    static func applyHeading(size: CGFloat) {
        guard let tv = textView, let storage = tv.textStorage else { return }
        let range = tv.selectedRange()
        let font = NSFontManager.shared.convert(
            NSFont(name: "Georgia-Bold", size: size) ?? NSFont.boldSystemFont(ofSize: size),
            toHaveTrait: .boldFontMask)
        guard range.length > 0 else {
            tv.typingAttributes[.font] = font; return
        }
        storage.addAttribute(.font, value: font, range: range)
        tv.didChangeText()
    }

    static func insertLinePrefix(_ prefix: String) {
        insert(prefix)
    }

    static func insert(_ string: String) {
        guard let tv = textView else { return }
        let range = tv.selectedRange()
        if tv.shouldChangeText(in: range, replacementString: string) {
            tv.textStorage?.replaceCharacters(in: range, with: string)
            tv.didChangeText()
        }
    }
}
#endif
