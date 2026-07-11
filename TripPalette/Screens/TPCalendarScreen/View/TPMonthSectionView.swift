import SwiftUI

struct TPMonthSectionView: View {
    let month: DateComponents
    @ObservedObject var viewModel: TPCalendarViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(monthTitle)
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.tp_textPrimary)
                .padding(.horizontal, 4)

            HStack(spacing: 0) {
                ForEach(Array(TPCalendarDate.weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.tp_textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }

            let days = TPCalendarDate.monthGrid(for: month)
            let rows = stride(from: 0, to: days.count, by: 7).map { start in
                Array(days[start..<min(start + 7, days.count)])
            }

            VStack(spacing: 2) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    TPWeekRowView(row: row, viewModel: viewModel)
                }
            }
        }
        .padding(.vertical, 12)
    }

    private var monthTitle: String {
        guard let date = TPCalendarDate.date(from: month) else { return "" }
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        return formatter.string(from: date).capitalized
    }
}
