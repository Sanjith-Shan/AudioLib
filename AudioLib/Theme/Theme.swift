import SwiftUI

// Rule: no shadow modifiers anywhere in this codebase. Depth via color contrast only.
enum Theme {
    enum Colors {
        static let dark      = Color(hex: 0x191C1F)
        static let white     = Color.white
        static let surface   = Color(hex: 0xF4F4F4)
        static let blue      = Color(hex: 0x494FDF)
        static let teal      = Color(hex: 0x00A87E)
        static let danger    = Color(hex: 0xE23B4A)
        static let warning   = Color(hex: 0xEC7E00)
        static let midSlate  = Color(hex: 0x505A63)
        static let coolGray  = Color(hex: 0x8D969E)
        static let grayTone  = Color(hex: 0xC9C9CD)
    }

    enum Radius {
        static let card: CGFloat      = 20
        static let cardSmall: CGFloat = 12
        static let pill: CGFloat      = 9999
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
        static let paddingH: CGFloat = 32
        static let paddingV: CGFloat = 14
    }
}
