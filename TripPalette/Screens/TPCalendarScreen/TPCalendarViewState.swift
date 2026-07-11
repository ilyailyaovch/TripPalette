import Foundation
import SwiftUI

enum TPCalendarDisplayMode: Hashable {
    case month
    case year
}

struct TPCalendarViewState: Equatable {
    var periods: [TPPeriod] = []
    var selectedDates: Set<DateComponents> = []
    var selectionAnchor: DateComponents?
    var displayMode: TPCalendarDisplayMode = .month
    var focusedMonth: DateComponents
    var periodDraft: TPPeriodDraft?
    var editSession: TPPeriodEditSession?
    var availableMonths: [DateComponents]
    var availableYears: [Int]

    init(
        focusedMonth: DateComponents = TPCalendarDate.monthComponents(from: Date()),
        availableMonths: [DateComponents] = [],
        availableYears: [Int] = [],
        periods: [TPPeriod] = []
    ) {
        self.focusedMonth = focusedMonth
        self.availableMonths = availableMonths
        self.availableYears = availableYears
        self.periods = periods
    }

    var displayModeToggleSystemImage: String {
        displayMode == .month ? "calendar" : "calendar.day.timeline.left"
    }

    var displayModeToggleTitle: String {
        displayMode == .month ? "Год" : "Месяц"
    }
}
