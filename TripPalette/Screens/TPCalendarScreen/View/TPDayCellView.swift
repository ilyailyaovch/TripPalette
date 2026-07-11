import SwiftUI

struct TPDayCellView: View {
    let day: DateComponents?
    let hasPeriod: Bool
    let isSelected: Bool
    let isToday: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void

    var body: some View {
        Group {
            if day != nil {
                Text("\(day?.day ?? 0)")
                    .font(.body.weight(isToday ? .bold : .regular))
                    .foregroundStyle(foregroundColor)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
                    .onTapGesture(perform: onTap)
                    .onLongPressGesture(minimumDuration: 0.35, perform: onLongPress)
            } else {
                Color.clear
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
        }
    }

    private var foregroundColor: Color {
        if isSelected {
            return Color.tp_selectionText
        }
        if hasPeriod {
            return .white
        }
        return Color.tp_textPrimary
    }
}
