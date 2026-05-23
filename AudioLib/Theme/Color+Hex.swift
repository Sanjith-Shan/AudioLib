import SwiftUI

extension Color {
    /// Initialise a Color from a 24-bit hex integer, e.g. `Color(hex: 0x494FDF)`.
    init(hex: Int) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }

    /// Initialise a Color from a 24-bit hex integer plus an opacity, e.g.
    /// `Color(hex: 0x1B1814, opacity: 0.62)`.
    init(hex: Int, opacity: Double) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}
