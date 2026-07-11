import SwiftUI

struct TPWeekRowView: View {
    let row: [DateComponents?]
    @ObservedObject var viewModel: TPCalendarViewModel

    var body: some View {
        ZStack {
            periodHighlights
            selectionHighlight

            HStack(spacing: 0) {
                ForEach(Array(row.enumerated()), id: \.offset) { _, day in
                    TPDayCellView(
                        day: day,
                        hasPeriod: day.map { !viewModel.colors(for: $0).isEmpty } ?? false,
                        isSelected: day.map(viewModel.isSelected) ?? false,
                        isToday: day.map(viewModel.isToday) ?? false,
                        onTap: {
                            if let day {
                                viewModel.tapDay(day)
                            }
                        },
                        onLongPress: {
                            if let day {
                                viewModel.longPressDay(day)
                            }
                        }
                    )
                }
            }
        }
    }

    private var periodHighlights: some View {
        GeometryReader { proxy in
            let metrics = barMetrics(in: proxy.size)

            ZStack(alignment: .leading) {
                ForEach(periodPaintSegments) { segment in
                    Capsule(style: .continuous)
                        .fill(segment.fillStyle)
                        .frame(
                            width: CGFloat(segment.end - segment.start + 1) * metrics.cellWidth - 4,
                            height: metrics.height
                        )
                        .offset(x: CGFloat(segment.start) * metrics.cellWidth + 2)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .animation(.smooth(duration: 0.34), value: viewModel.state.periods)
    }

    private var selectionHighlight: some View {
        GeometryReader { proxy in
            let metrics = barMetrics(in: proxy.size)

            if let bounds = selectionBounds {
                Capsule(style: .continuous)
                    .fill(Color.tp_selectionHighlight)
                    .frame(
                        width: CGFloat(bounds.end - bounds.start + 1) * metrics.cellWidth - 4,
                        height: metrics.height
                    )
                    .offset(x: CGFloat(bounds.start) * metrics.cellWidth + 2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
        }
        .animation(.smooth(duration: 0.34), value: selectionBounds)
    }

    private func barMetrics(in size: CGSize) -> (cellWidth: CGFloat, height: CGFloat) {
        let cellWidth = size.width / CGFloat(max(row.count, 1))
        let height = min(size.height - 4, cellWidth - 4)
        return (cellWidth, height)
    }

    private var selectionBounds: TPRowBounds? {
        let indices = row.indices.filter { index in
            row[index].map(viewModel.isSelected) ?? false
        }
        guard let start = indices.first, let end = indices.last else { return nil }
        return TPRowBounds(start: start, end: end)
    }

    /// One continuous capsule per contiguous covered range.
    /// Overlaps become local gradient stops; exclusive days stay solid.
    private var periodPaintSegments: [TPPeriodPaintSegment] {
        var segments: [TPPeriodPaintSegment] = []
        var segmentStart: Int?
        var dayColorsInSegment: [[Color]] = []

        func closeSegment(at end: Int) {
            guard let start = segmentStart, !dayColorsInSegment.isEmpty else {
                segmentStart = nil
                dayColorsInSegment = []
                return
            }
            segments.append(
                TPPeriodPaintSegment(
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

private struct TPRowBounds: Equatable {
    let start: Int
    let end: Int
}

private struct TPPeriodPaintSegment: Identifiable, Equatable {
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
                let step = (dayEnd - dayStart) / CGFloat(colors.count - 1)
                for (colorIndex, color) in colors.enumerated() {
                    let location = dayStart + step * CGFloat(colorIndex)
                    appendStop(color: color, location: location, into: &stops)
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
