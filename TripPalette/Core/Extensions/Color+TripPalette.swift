import SwiftUI
import UIKit

extension Color {
    static let tp_tint = Color("Tint")
    static let tp_selectionHighlight = Color("Tint").opacity(0.28)
    static let tp_selectionText = Color(red: 1.0, green: 0.23, blue: 0.19)
    static let tp_backgroundPrimary = Color("BackgroundPrimary")
    static let tp_backgroundSecondary = Color("BackgroundSecondary")
    static let tp_textPrimary = Color("TextPrimary")
    static let tp_textSecondary = Color("TextSecondary")

    var tp_hexString: String {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return String(
            format: "%02X%02X%02X",
            Int((red * 255).rounded()),
            Int((green * 255).rounded()),
            Int((blue * 255).rounded())
        )
    }

    init(tp_hex: String) {
        let cleaned = tp_hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard cleaned.count == 6, let value = UInt64(cleaned, radix: 16) else {
            self = .tp_tint
            return
        }
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}
