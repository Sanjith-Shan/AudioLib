import SwiftUI
#if os(iOS)
import UIKit
#else
import AppKit
#endif

// MARK: - Design font helpers
//
// The design uses three families:
//   • Georgia serif — book titles, large display, nav large titles
//   • SF Pro (system) — all UI text
//   • Monospace tabular — timestamps, durations, URLs, version

extension Font {
    /// Georgia serif at an explicit size/weight (book titles, display headers).
    static func serif(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .custom("Georgia", size: size).weight(weight)
    }

    /// System (SF Pro) UI font at an explicit size/weight.
    static func ui(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }

    /// Monospaced system font with tabular figures (timestamps, durations).
    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    // MARK: - Named tokens (mapped onto the design scale)

    /// Onboarding app name — Georgia 40 / bold.
    static var displayLg: Font { .serif(34, weight: .bold) }
    /// Large serif headers (nav titles) — Georgia 28 / bold.
    static var serifTitle: Font { .serif(28, weight: .bold) }
    /// Player / note titles — Georgia 24 / bold.
    static var titleLg: Font { .serif(22, weight: .bold) }
    /// Section / card headline — SF Pro 17 / semibold.
    static var titleMd: Font { .ui(17, weight: .semibold) }

    /// Body — SF Pro 16 / regular.
    static var bodyRegular: Font { .ui(16) }
    /// Body emphasis — SF Pro 15 / semibold (row titles).
    static var bodySemibold: Font { .ui(15, weight: .semibold) }

    /// Caption — SF Pro 13 / regular (row secondary text).
    static var caption: Font { .ui(13) }
    /// Small caption — SF Pro 11.5 / regular.
    static var captionSmall: Font { .ui(11.5) }
    /// Uppercase section header — SF Pro 13 / semibold.
    static var sectionHeader: Font { .ui(13, weight: .semibold) }
}

// MARK: - View extensions (legacy convenience wrappers)

extension View {
    func audioLibDisplayLg() -> some View { font(.displayLg) }
    func audioLibTitleLg() -> some View { font(.titleLg) }
    func audioLibTitleMd() -> some View { font(.titleMd) }
    func audioLibBodyRegular() -> some View { font(.bodyRegular) }
    func audioLibBodySemibold() -> some View { font(.bodySemibold) }
    func audioLibCaption() -> some View { font(.caption) }
    func audioLibCaptionSmall() -> some View { font(.captionSmall) }
}
