import SwiftUI
import UIKit

struct TPPeriodPaletteColor: Identifiable, Equatable {
    let id: String
    let color: Color
}

enum TPPeriodPalette {
    static let `default` = colors[0]

    static let colors: [TPPeriodPaletteColor] = [
        .init(id: "tint", color: .tp_tint),
        .init(id: "ocean", color: Color(red: 0.18, green: 0.52, blue: 0.78)),
        .init(id: "sky", color: Color(red: 0.29, green: 0.55, blue: 0.96)),
        .init(id: "teal", color: Color(red: 0.20, green: 0.66, blue: 0.55)),
        .init(id: "mint", color: Color(red: 0.30, green: 0.74, blue: 0.62)),
        .init(id: "sage", color: Color(red: 0.45, green: 0.62, blue: 0.48)),
        .init(id: "forest", color: Color(red: 0.22, green: 0.48, blue: 0.38)),
        .init(id: "sand", color: Color(red: 0.86, green: 0.70, blue: 0.42)),
        .init(id: "amber", color: Color(red: 0.95, green: 0.55, blue: 0.25)),
        .init(id: "terracotta", color: Color(red: 0.82, green: 0.40, blue: 0.32)),
        .init(id: "coral", color: Color(red: 0.92, green: 0.42, blue: 0.45)),
        .init(id: "rose", color: Color(red: 0.78, green: 0.36, blue: 0.52)),
        .init(id: "berry", color: Color(red: 0.62, green: 0.28, blue: 0.48)),
        .init(id: "lavender", color: Color(red: 0.58, green: 0.40, blue: 0.85)),
        .init(id: "indigo", color: Color(red: 0.38, green: 0.36, blue: 0.72)),
        .init(id: "slate", color: Color(red: 0.35, green: 0.45, blue: 0.55)),
        .init(id: "stone", color: Color(red: 0.48, green: 0.50, blue: 0.52)),
        .init(id: "charcoal", color: Color(red: 0.28, green: 0.30, blue: 0.34)),
    ]

    static func closest(to color: Color) -> Color {
        colors.first(where: { matches($0.color, color) })?.color ?? color
    }

    static func matches(_ lhs: Color, _ rhs: Color) -> Bool {
        let left = UIColor(lhs)
        let right = UIColor(rhs)
        var lr: CGFloat = 0, lg: CGFloat = 0, lb: CGFloat = 0, la: CGFloat = 0
        var rr: CGFloat = 0, rg: CGFloat = 0, rb: CGFloat = 0, ra: CGFloat = 0
        left.getRed(&lr, green: &lg, blue: &lb, alpha: &la)
        right.getRed(&rr, green: &rg, blue: &rb, alpha: &ra)
        return abs(lr - rr) < 0.02
            && abs(lg - rg) < 0.02
            && abs(lb - rb) < 0.02
            && abs(la - ra) < 0.02
    }
}
