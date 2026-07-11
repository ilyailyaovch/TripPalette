import SwiftUI

struct TPYearGridView: View {
    @ObservedObject var viewModel: TPCalendarViewModel
    @State private var isPositioned = false
    @State private var scrollYear: Int?

    private var currentYear: Int {
        viewModel.state.focusedMonth.year
            ?? TPCalendarDate.calendar.component(.year, from: Date())
    }

    private var positioningID: String {
        "\(currentYear)-\(viewModel.state.availableYears.map(String.init).joined(separator: ","))"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                ForEach(viewModel.state.availableYears, id: \.self) { year in
                    yearSection(year)
                        .id(year)
                }
            }
            .scrollTargetLayout()
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .scrollPosition(id: $scrollYear, anchor: .top)
        .opacity(isPositioned ? 1 : 0)
        .task(id: positioningID) {
            await positionOnCurrentYear()
        }
    }

    private func yearSection(_ year: Int) -> some View {
        let isCurrentYear = year == currentYear

        return VStack(alignment: .leading, spacing: 12) {
            Text(String(year))
                .font(.title.weight(.bold))
                .foregroundStyle(isCurrentYear ? Color.tp_tint : Color.tp_textPrimary)

            Grid(horizontalSpacing: 16, verticalSpacing: 16) {
                ForEach(0..<4, id: \.self) { row in
                    GridRow {
                        ForEach(0..<3, id: \.self) { column in
                            let month = row * 3 + column + 1
                            let components = DateComponents(year: year, month: month)
                            Button {
                                viewModel.focus(month: components)
                            } label: {
                                TPMiniMonthView(month: components, viewModel: viewModel)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    @MainActor
    private func positionOnCurrentYear() async {
        isPositioned = false
        // scrollPosition реагирует на изменение значения, а не на initial — сначала сбрасываем.
        scrollYear = nil
        await Task.yield()
        scrollYear = currentYear
        try? await Task.sleep(for: .milliseconds(50))
        scrollYear = currentYear
        isPositioned = true
    }
}

private struct TPMiniMonthView: View {
    let month: DateComponents
    @ObservedObject var viewModel: TPCalendarViewModel

    private let dayHeight: CGFloat = 12
    private let weekSpacing: CGFloat = 2
    private let weekRowsCount = 6

    private var weeksHeight: CGFloat {
        CGFloat(weekRowsCount) * dayHeight + CGFloat(weekRowsCount - 1) * weekSpacing
    }

    var body: some View {
        let days = paddedMonthGrid
        let rows = stride(from: 0, to: days.count, by: 7).map { start in
            Array(days[start..<min(start + 7, days.count)])
        }

        VStack(alignment: .leading, spacing: 6) {
            Text(monthName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.tp_tint)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: weekSpacing) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    TPMiniWeekRowView(
                        row: row,
                        viewModel: viewModel,
                        dayHeight: dayHeight
                    )
                }
            }
            .frame(height: weeksHeight, alignment: .top)
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.tp_backgroundSecondary)
        )
    }

    /// Always 6 weeks so every mini-month has the same height.
    private var paddedMonthGrid: [DateComponents?] {
        var days = TPCalendarDate.monthGrid(for: month)
        let targetCount = weekRowsCount * 7
        if days.count < targetCount {
            days.append(contentsOf: Array(repeating: nil, count: targetCount - days.count))
        }
        return days
    }

    private var monthName: String {
        guard let date = TPCalendarDate.date(from: month) else { return "" }
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.setLocalizedDateFormatFromTemplate("MMM")
        return formatter.string(from: date).capitalized
    }
}

private struct TPMiniWeekRowView: View {
    let row: [DateComponents?]
    @ObservedObject var viewModel: TPCalendarViewModel
    let dayHeight: CGFloat

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(row.enumerated()), id: \.offset) { _, day in
                if let day {
                    let hasPeriod = !viewModel.colors(for: day).isEmpty
                    let isToday = viewModel.isToday(day)
                    Text("\(day.day ?? 0)")
                        .font(.system(size: 8, weight: isToday ? .bold : .medium))
                        .foregroundStyle(hasPeriod ? Color.white : Color.tp_textSecondary)
                        .frame(maxWidth: .infinity, minHeight: dayHeight, maxHeight: dayHeight)
                } else {
                    Color.clear
                        .frame(maxWidth: .infinity, minHeight: dayHeight, maxHeight: dayHeight)
                }
            }
        }
        .frame(height: dayHeight)
        .background(alignment: .leading) {
            periodHighlights
        }
    }

    private var periodHighlights: some View {
        GeometryReader { proxy in
            let cellWidth = proxy.size.width / CGFloat(max(row.count, 1))

            ForEach(periodPaintSegments) { segment in
                Capsule(style: .continuous)
                    .fill(segment.fillStyle)
                    .frame(
                        width: max(CGFloat(segment.end - segment.start + 1) * cellWidth - 1, 0),
                        height: dayHeight
                    )
                    .offset(x: CGFloat(segment.start) * cellWidth + 0.5)
            }
        }
    }

    private var periodPaintSegments: [TPMiniPeriodPaintSegment] {
        var segments: [TPMiniPeriodPaintSegment] = []
        var segmentStart: Int?
        var dayColorsInSegment: [[Color]] = []

        func closeSegment(at end: Int) {
            guard let start = segmentStart, !dayColorsInSegment.isEmpty else {
                segmentStart = nil
                dayColorsInSegment = []
                return
            }
            segments.append(
                TPMiniPeriodPaintSegment(
                    id: "\(start)-\(end)",
                    start: start,
                    end: end,
                    dayColors: dayColorsInSegment
                )
            )
            segmentStart = nil
            dayColorsInSegment = []
        }

        for index in row.indices {
            let colors = row[index].map(viewModel.colors(for:)) ?? []
            if colors.isEmpty {
                if segmentStart != nil {
                    closeSegment(at: index - 1)
                }
                continue
            }

            if segmentStart == nil {
                segmentStart = index
            }
            dayColorsInSegment.append(colors)
        }

        if segmentStart != nil {
            closeSegment(at: row.count - 1)
        }

        return segments
    }
}

private struct TPMiniPeriodPaintSegment: Identifiable, Equatable {
    let id: String
    let start: Int
    let end: Int
    let dayColors: [[Color]]

    var fillStyle: AnyShapeStyle {
        let stops = gradientStops
        if stops.count <= 1 {
            return AnyShapeStyle((stops.first?.color ?? .clear).opacity(0.9))
        }
        return AnyShapeStyle(
            LinearGradient(
                gradient: Gradient(stops: stops.map {
                    .init(color: $0.color.opacity(0.9), location: $0.location)
                }),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }

    private var gradientStops: [(color: Color, location: CGFloat)] {
        let dayCount = max(dayColors.count, 1)
        var stops: [(color: Color, location: CGFloat)] = []

        for (dayIndex, colors) in dayColors.enumerated() {
            let dayStart = CGFloat(dayIndex) / CGFloat(dayCount)
            let dayEnd = CGFloat(dayIndex + 1) / CGFloat(dayCount)
            guard !colors.isEmpty else { continue }

            if colors.count == 1 {
                let color = colors[0]
                appendStop(color: color, location: dayStart, into: &stops)
                appendStop(color: color, location: dayEnd, into: &stops)
            } else {
                let step = (dayEnd - dayStart) / CGFloat(max(colors.count - 1, 1))
                for (colorIndex, color) in colors.enumerated() {
                    appendStop(
                        color: color,
                        location: dayStart + step * CGFloat(colorIndex),
                        into: &stops
                    )
                }
            }
        }

        return stops
    }

    private func appendStop(
        color: Color,
        location: CGFloat,
        into stops: inout [(color: Color, location: CGFloat)]
    ) {
        if let last = stops.last, abs(last.location - location) < 0.0001 {
            stops[stops.count - 1] = (color, location)
        } else {
            stops.append((color, location))
        }
    }
}
