import Foundation

enum TPCalendarDate {
    static let calendar = Calendar.current

    static func dayComponents(from date: Date) -> DateComponents {
        calendar.dateComponents([.year, .month, .day], from: date)
    }

    static func monthComponents(from date: Date) -> DateComponents {
        calendar.dateComponents([.year, .month], from: date)
    }

    static func date(from components: DateComponents) -> Date? {
        calendar.date(from: DateComponents(
            year: components.year,
            month: components.month,
            day: components.day ?? 1
        ))
    }

    static func isSameDay(_ lhs: DateComponents, _ rhs: DateComponents) -> Bool {
        lhs.year == rhs.year && lhs.month == rhs.month && lhs.day == rhs.day
    }

    static func isSameMonth(_ lhs: DateComponents, _ rhs: DateComponents) -> Bool {
        lhs.year == rhs.year && lhs.month == rhs.month
    }

    static func daysInRange(from start: DateComponents, to end: DateComponents) -> Set<DateComponents> {
        guard
            let startDate = date(from: start),
            let endDate = date(from: end)
        else {
            return []
        }

        let lower = min(startDate, endDate)
        let upper = max(startDate, endDate)
        var result: Set<DateComponents> = []
        var current = lower

        while current <= upper {
            result.insert(dayComponents(from: current))
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }

        return result
    }

    static func monthGrid(for month: DateComponents) -> [DateComponents?] {
        guard
            let monthDate = date(from: DateComponents(year: month.year, month: month.month, day: 1)),
            let dayRange = calendar.range(of: .day, in: .month, for: monthDate)
        else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: monthDate)
        let leadingEmpty = (firstWeekday - calendar.firstWeekday + 7) % 7

        var cells: [DateComponents?] = Array(repeating: nil, count: leadingEmpty)
        for day in dayRange {
            cells.append(DateComponents(year: month.year, month: month.month, day: day))
        }

        while cells.count % 7 != 0 {
            cells.append(nil)
        }

        return cells
    }

    static func months(from start: DateComponents, count: Int) -> [DateComponents] {
        guard let startDate = date(from: start) else { return [] }
        return (0..<count).compactMap { offset in
            guard let date = calendar.date(byAdding: .month, value: offset, to: startDate) else {
                return nil
            }
            return monthComponents(from: date)
        }
    }

    static func years(around year: Int, radius: Int = 3) -> [Int] {
        ((year - radius)...(year + radius)).map { $0 }
    }

    static var weekdaySymbols: [String] {
        let symbols = calendar.veryShortWeekdaySymbols
        let first = calendar.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first])
    }
}
