import SwiftUI

extension Color {
    /// Initialise a Color from a 24-bit hex integer, e.g. `Color(hex: 0x494FDF)`.
    init(hex: Int) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
