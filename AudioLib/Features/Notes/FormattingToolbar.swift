#if os(iOS)
import UIKit

class FormattingToolbar: UIToolbar {
    weak var textView: UITextView?

    init(textView: UITextView) {
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: 44))
        self.textView = textView
        setupItems()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupItems() {
        barTintColor = UIColor(red: 0xF4/255, green: 0xF4/255, blue: 0xF4/255, alpha: 1)

        let bold = makeButton(title: "B", bold: true, action: #selector(didTapBold))
        let italic = makeButton(title: "I", italic: true, action: #selector(didTapItalic))
        let underline = makeButton(title: "U", underline: true, action: #selector(didTapUnderline))
        let h1 = makeButton(title: "H1", action: #selector(didTapH1))
        let h2 = makeButton(title: "H2", action: #selector(didTapH2))
        let bullet = makeButton(title: "•", action: #selector(didTapBullet))
        let numbered = makeButton(title: "1.", action: #selector(didTapNumbered))
        let clear = makeButton(title: "Clear", action: #selector(didTapClear))
        let timestamp = UIBarButtonItem(
            image: UIImage(systemName: "clock"),
            style: .plain,
            target: self,
            action: #selector(didTapTimestamp)
        )
        timestamp.tintColor = UIColor(red: 0x1E/255, green: 0x90/255, blue: 0x85/255, alpha: 1)
        timestamp.isEnabled = PlayerController.shared.currentBook != nil
        self.timestampItem = timestamp
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dismissKeyboard))
        done.tintColor = UIColor(red: 0x1E/255, green: 0x90/255, blue: 0x85/255, alpha: 1)

        items = [bold, italic, underline, flex, h1, h2, flex, bullet, numbered, flex, timestamp, flex, clear, flex, done]
    }

    private var timestampItem: UIBarButtonItem?

    @objc private func didTapTimestamp() {
        guard let tv = textView, let book = PlayerController.shared.currentBook else { return }
        let title = book.title
        let stamp = DurationFormatter.timestamp(seconds: PlayerController.shared.currentTime)
        let text = "[\(title) @ \(stamp)]\n"

        let defaultFont = UIFont(name: "Inter-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16)
        let insertion = NSAttributedString(string: text, attributes: [
            .font: defaultFont,
            .foregroundColor: UIColor.black
        ])
        let range = tv.selectedRange
        let attrStr = NSMutableAttributedString(attributedString: tv.attributedText)
        attrStr.replaceCharacters(in: range, with: insertion)
        tv.attributedText = attrStr
        tv.selectedRange = NSRange(location: range.location + (text as NSString).length, length: 0)
    }

    private func makeButton(title: String, bold: Bool = false, italic: Bool = false, underline: Bool = false, action: Selector) -> UIBarButtonItem {
        var attrs: [NSAttributedString.Key: Any] = [:]
        var descriptor = UIFont.systemFont(ofSize: 15).fontDescriptor
        var traits: UIFontDescriptor.SymbolicTraits = []
        if bold { traits.insert(.traitBold) }
        if italic { traits.insert(.traitItalic) }
        if let d = descriptor.withSymbolicTraits(traits) { descriptor = d }
        attrs[.font] = UIFont(descriptor: descriptor, size: 15)
        if underline { attrs[.underlineStyle] = NSUnderlineStyle.single.rawValue }

        let button = UIButton(type: .system)
        button.setAttributedTitle(NSAttributedString(string: title, attributes: attrs), for: .normal)
        button.sizeToFit()
        button.addTarget(self, action: action, for: .touchUpInside)
        return UIBarButtonItem(customView: button)
    }

    @objc private func didTapBold() {
        applyTrait(.traitBold)
    }

    @objc private func didTapItalic() {
        applyTrait(.traitItalic)
    }

    @objc private func didTapUnderline() {
        guard let tv = textView else { return }
        let range = tv.selectedRange
        guard range.length > 0 else {
            // Toggle typing attribute
            var attrs = tv.typingAttributes
            let current = attrs[.underlineStyle] as? Int ?? 0
            attrs[.underlineStyle] = current == 0 ? NSUnderlineStyle.single.rawValue : 0
            tv.typingAttributes = attrs
            return
        }

        let attrStr = NSMutableAttributedString(attributedString: tv.attributedText)
        let current = attrStr.attribute(.underlineStyle, at: range.location, effectiveRange: nil) as? Int ?? 0
        let newValue = current == 0 ? NSUnderlineStyle.single.rawValue : 0
        attrStr.addAttribute(.underlineStyle, value: newValue, range: range)
        tv.attributedText = attrStr
        tv.selectedRange = range
    }

    @objc private func didTapH1() {
        applyHeading(size: 28, weight: .semibold)
    }

    @objc private func didTapH2() {
        applyHeading(size: 22, weight: .medium)
    }

    @objc private func didTapBullet() {
        insertListPrefix("• ")
    }

    @objc private func didTapNumbered() {
        guard let tv = textView else { return }
        let text = tv.text as NSString
        let lineRange = text.lineRange(for: tv.selectedRange)
        let lineStart = lineRange.location

        // Count existing numbered items above the cursor to determine next number
        let preceding = text.substring(to: lineStart)
        let existingCount = preceding.components(separatedBy: "\n")
            .filter { $0.range(of: "^\\d+\\. ", options: .regularExpression) != nil }
            .count
        insertListPrefix("\(existingCount + 1). ")
    }

    @objc private func didTapClear() {
        guard let tv = textView else { return }
        let range = tv.selectedRange
        guard range.length > 0 else { return }
        let attrStr = NSMutableAttributedString(attributedString: tv.attributedText)
        let defaultFont = UIFont(name: "Inter-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16)
        attrStr.setAttributes([
            .font: defaultFont,
            .foregroundColor: UIColor.black
        ], range: range)
        tv.attributedText = attrStr
        tv.selectedRange = range
    }

    @objc private func dismissKeyboard() {
        textView?.resignFirstResponder()
    }

    // MARK: - Helpers

    private func applyTrait(_ trait: UIFontDescriptor.SymbolicTraits) {
        guard let tv = textView else { return }
        let range = tv.selectedRange

        guard range.length > 0 else {
            // Toggle on typing attributes
            var attrs = tv.typingAttributes
            let font = attrs[.font] as? UIFont ?? UIFont.systemFont(ofSize: 16)
            let descriptor = font.fontDescriptor
            var traits = descriptor.symbolicTraits
            if traits.contains(trait) { traits.remove(trait) } else { traits.insert(trait) }
            if let newDescriptor = descriptor.withSymbolicTraits(traits) {
                attrs[.font] = UIFont(descriptor: newDescriptor, size: font.pointSize)
            }
            tv.typingAttributes = attrs
            return
        }

        let attrStr = NSMutableAttributedString(attributedString: tv.attributedText)
        attrStr.enumerateAttribute(.font, in: range, options: []) { value, subrange, _ in
            let font = value as? UIFont ?? UIFont.systemFont(ofSize: 16)
            let descriptor = font.fontDescriptor
            var traits = descriptor.symbolicTraits
            if traits.contains(trait) { traits.remove(trait) } else { traits.insert(trait) }
            if let newDescriptor = descriptor.withSymbolicTraits(traits) {
                attrStr.addAttribute(.font, value: UIFont(descriptor: newDescriptor, size: font.pointSize), range: subrange)
            }
        }
        tv.attributedText = attrStr
        tv.selectedRange = range
    }

    private func applyHeading(size: CGFloat, weight: UIFont.Weight) {
        guard let tv = textView else { return }
        let range = tv.selectedRange
        let paragraphRange: NSRange

        if range.length > 0 {
            paragraphRange = range
        } else {
            // Apply to current line
            let text = tv.text as NSString
            paragraphRange = text.paragraphRange(for: range)
        }

        let attrStr = NSMutableAttributedString(attributedString: tv.attributedText)
        attrStr.addAttribute(.font, value: UIFont.systemFont(ofSize: size, weight: weight), range: paragraphRange)
        tv.attributedText = attrStr
        tv.selectedRange = range
    }

    private func insertListPrefix(_ prefix: String) {
        guard let tv = textView else { return }
        let range = tv.selectedRange
        let text = tv.text as NSString
        let lineRange = text.lineRange(for: range)

        let defaultFont = UIFont(name: "Inter-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16)
        let insertion = NSAttributedString(string: prefix, attributes: [
            .font: defaultFont,
            .foregroundColor: UIColor.black
        ])

        let attrStr = NSMutableAttributedString(attributedString: tv.attributedText)
        attrStr.insert(insertion, at: lineRange.location)
        tv.attributedText = attrStr
        tv.selectedRange = NSRange(location: range.location + prefix.count, length: range.length)
    }
}
#endif
