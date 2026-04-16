import SwiftUI

// MARK: - Font static properties

extension Font {
    /// AeonikPro-Medium 34pt — display heading
    static var displayLg: Font {
        if let _ = UIFont(name: "AeonikPro-Medium", size: 34) {
            return .custom("AeonikPro-Medium", size: 34)
        }
        return .system(.largeTitle, design: .default).weight(.medium)
    }

    /// AeonikPro-Medium 22pt — title large
    static var titleLg: Font {
        if let _ = UIFont(name: "AeonikPro-Medium", size: 22) {
            return .custom("AeonikPro-Medium", size: 22)
        }
        return .system(.title2, design: .default).weight(.medium)
    }

    /// AeonikPro-Medium 17pt — title medium
    static var titleMd: Font {
        if let _ = UIFont(name: "AeonikPro-Medium", size: 17) {
            return .custom("AeonikPro-Medium", size: 17)
        }
        return .system(.headline, design: .default).weight(.medium)
    }

    /// Inter-Regular 16pt — body regular
    static var bodyRegular: Font {
        if let _ = UIFont(name: "Inter-Regular", size: 16) {
            return .custom("Inter-Regular", size: 16)
        }
        return .system(.body, design: .default)
    }

    /// Inter-SemiBold 16pt — body semibold
    static var bodySemibold: Font {
        if let _ = UIFont(name: "Inter-SemiBold", size: 16) {
            return .custom("Inter-SemiBold", size: 16)
        }
        return .system(.body, design: .default).weight(.semibold)
    }

    /// Inter-Regular 13pt — caption
    static var caption: Font {
        if let _ = UIFont(name: "Inter-Regular", size: 13) {
            return .custom("Inter-Regular", size: 13)
        }
        return .system(.caption, design: .default)
    }

    /// Inter-Regular 11pt — caption small
    static var captionSmall: Font {
        if let _ = UIFont(name: "Inter-Regular", size: 11) {
            return .custom("Inter-Regular", size: 11)
        }
        return .system(.caption2, design: .default)
    }
}

// MARK: - ViewModifier variants

struct AudioLibDisplayLgModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.displayLg)
    }
}

struct AudioLibTitleLgModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.titleLg)
    }
}

struct AudioLibTitleMdModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.titleMd)
    }
}

struct AudioLibBodyRegularModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.bodyRegular)
    }
}

struct AudioLibBodySemiboldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.bodySemibold)
    }
}

struct AudioLibCaptionModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.caption)
    }
}

struct AudioLibCaptionSmallModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.captionSmall)
    }
}

// MARK: - View extensions

extension View {
    func audioLibDisplayLg() -> some View {
        modifier(AudioLibDisplayLgModifier())
    }

    func audioLibTitleLg() -> some View {
        modifier(AudioLibTitleLgModifier())
    }

    func audioLibTitleMd() -> some View {
        modifier(AudioLibTitleMdModifier())
    }

    func audioLibBodyRegular() -> some View {
        modifier(AudioLibBodyRegularModifier())
    }

    func audioLibBodySemibold() -> some View {
        modifier(AudioLibBodySemiboldModifier())
    }

    func audioLibCaption() -> some View {
        modifier(AudioLibCaptionModifier())
    }

    func audioLibCaptionSmall() -> some View {
        modifier(AudioLibCaptionSmallModifier())
    }
}
