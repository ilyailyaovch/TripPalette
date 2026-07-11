import Foundation

enum TPPeriodsListSortOrder: String, CaseIterable, Identifiable, Equatable {
    case startAscending
    case startDescending
    case titleAscending

    var id: String { rawValue }

    var title: String {
        switch self {
        case .startAscending:
            return "По дате · сначала ближайшие"
        case .startDescending:
            return "По дате · сначала дальние"
        case .titleAscending:
            return "По названию"
        }
    }
}

struct TPPeriodsListViewState: Equatable {
    var sourcePeriods: [TPPeriod] = []
    var sortOrder: TPPeriodsListSortOrder = .startAscending
    var showOnlyUpcoming: Bool = false

    var periods: [TPPeriod] {
        var result = sourcePeriods

        if showOnlyUpcoming {
            let startOfToday = TPCalendarDate.calendar.startOfDay(for: Date())
            result = result.filter { period in
                guard let end = Self.endDate(of: period) else { return false }
                return end >= startOfToday
            }
        }

        switch sortOrder {
        case .startAscending:
            return result.sorted { lhs, rhs in
                Self.compareByStart(lhs, rhs, ascending: true)
            }
        case .startDescending:
            return result.sorted { lhs, rhs in
                Self.compareByStart(lhs, rhs, ascending: false)
            }
        case .titleAscending:
            return result.sorted { lhs, rhs in
                Self.displayTitle(lhs).localizedCaseInsensitiveCompare(Self.displayTitle(rhs))
                    == .orderedAscending
            }
        }
    }

    private static func startDate(of period: TPPeriod) -> Date? {
        period.dates.compactMap(TPCalendarDate.date(from:)).min()
    }

    private static func endDate(of period: TPPeriod) -> Date? {
        period.dates.compactMap(TPCalendarDate.date(from:)).max()
    }

    private static func compareByStart(_ lhs: TPPeriod, _ rhs: TPPeriod, ascending: Bool) -> Bool {
        let lhsStart = startDate(of: lhs) ?? .distantFuture
        let rhsStart = startDate(of: rhs) ?? .distantFuture
        if lhsStart != rhsStart {
            return ascending ? lhsStart < rhsStart : lhsStart > rhsStart
        }
        return displayTitle(lhs).localizedCaseInsensitiveCompare(displayTitle(rhs)) == .orderedAscending
    }

    private static func displayTitle(_ period: TPPeriod) -> String {
        let emoji = period.emoji?.trimmingCharacters(in: .whitespacesAndNewlines)
        let title = period.title?.trimmingCharacters(in: .whitespacesAndNewlines)

        switch (emoji?.isEmpty == false, title?.isEmpty == false) {
        case (true, true):
            return "\(emoji!) \(title!)"
        case (true, false):
            return emoji!
        case (false, true):
            return title!
        case (false, false):
            return "Без названия"
        }
    }
}
