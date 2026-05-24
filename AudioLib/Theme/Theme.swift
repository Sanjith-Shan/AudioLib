import SwiftUI

// AudioLib design system — "warm paper" light theme with a deep-blue dark Player.
// Single teal accent. Georgia serif for titles, SF Pro for UI, monospace for time.
enum Theme {
    enum Colors {
        // ── Warm paper palette (tabs, settings, notes, library, download) ──
        static let paper     = Color(hex: 0xF1ECE2)   // primary background
        static let paperAlt  = Color(hex: 0xE8E2D4)   // onboarding gradient stop
        static let card      = Color(hex: 0xFFFFFF)    // list cards, rows
        static let cardSoft  = Color(hex: 0xF8F5EE)    // inset fields, empty-state circles
        static let ink       = Color(hex: 0x1B1814)    // primary text + primary CTAs
        static let inkSoft   = Color(hex: 0x1B1814, opacity: 0.62) // secondary text
        static let inkMute   = Color(hex: 0x1B1814, opacity: 0.38) // tertiary, placeholders
        static let inkFaint  = Color(hex: 0x1B1814, opacity: 0.12) // icon backgrounds, tracks
        static let hair      = Color(hex: 0x1B1814, opacity: 0.08) // row separators

        // ── Accent: teal ──
        static let teal      = Color(hex: 0x1E9085)
        static let tealSoft  = Color(hex: 0xD4ECE9)    // soft pill backgrounds
        static let tealInk   = Color(hex: 0x0E5751)    // text on teal-soft

        // ── Destructive ──
        static let red       = Color(hex: 0xC8443A)

        // ── Player (dark) ──
        static let dBg       = Color(hex: 0x0D0D10)
        static let dCard     = Color(hex: 0x1B1B20)
        static let dSheet    = Color(hex: 0x1C1C1F)    // dark modal sheet bg
        static let dSheetRow = Color(hex: 0x2A2A2F)    // grouped rows inside dark sheets
        static let dInk      = Color.white
        static let dInkSoft  = Color(hex: 0xFFFFFF, opacity: 0.62)
        static let dInkMute  = Color(hex: 0xFFFFFF, opacity: 0.38)
        static let dInkFaint = Color(hex: 0xFFFFFF, opacity: 0.12)

        // ── Paper used as foreground on dark/teal surfaces ──
        static let paperFg   = Color(hex: 0xF4ECDB)

        // ── Legacy aliases (kept so any untouched references still resolve) ──
        static let dark      = ink
        static let white     = card
        static let surface   = cardSoft
        static let blue      = teal
        static let danger    = red
        static let warning   = Color(hex: 0xEC7E00)
        static let midSlate  = inkSoft
        static let coolGray  = inkMute
        static let grayTone  = inkFaint
    }

    enum Gradients {
        /// Full-screen Player background (top → bottom).
        static let player = LinearGradient(
            colors: [Color(hex: 0x1B4B7A), Color(hex: 0x0E1E33), Color(hex: 0x0A0A12)],
            startPoint: .top,
            endPoint: .bottom
        )

        /// Continue-Listening banner.
        static let continueListening = LinearGradient(
            colors: [Color(hex: 0x11332E), Color(hex: 0x1B5751)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        /// Onboarding background wash.
        static let onboarding = LinearGradient(
            colors: [Color(hex: 0xF5F2EB), Color(hex: 0xE8DFC9)],
            startPoint: .top,
            endPoint: .bottom
        )

        /// App icon glyph background.
        static let appIcon = LinearGradient(
            colors: [Color(hex: 0x0F5751), Color(hex: 0x1E9085)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    enum Radius {
        static let card: CGFloat       = 18   // list cards / sheets
        static let cardLarge: CGFloat  = 20   // hero cards (add, continue listening)
        static let cardSmall: CGFloat  = 14   // rows, inner cards
        static let field: CGFloat      = 12   // inset fields
        static let button: CGFloat     = 12   // buttons / pills (rect)
        static let cover: CGFloat      = 8    // row cover art
        static let coverLarge: CGFloat = 14   // player cover art
        static let pill: CGFloat       = 9999
    }

    enum Spacing {
        static let xs: CGFloat  = 4
        static let sm: CGFloat  = 8
        static let md: CGFloat  = 16
        static let lg: CGFloat  = 24
        static let xl: CGFloat  = 32
        static let xxl: CGFloat = 48
    }

    enum Button {
        static let paddingH: CGFloat = 22
        static let paddingV: CGFloat = 14
    }
}
