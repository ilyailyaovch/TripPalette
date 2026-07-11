import Combine
import SwiftUI

@MainActor
final class TPCalendarViewModel: ObservableObject {
    @Published private(set) var state: TPCalendarViewState

    let router: TPCalendarRouter

    private let periodService: TPPeriodService
    private let planService: TPPeriodPlanService
    private let calendar = TPCalendarDate.calendar
    private var cancellables = Set<AnyCancellable>()

    init(
        router: TPCalendarRouter,
        periodService: TPPeriodService,
        planService: TPPeriodPlanService
    ) {
        self.router = router
        self.periodService = periodService
        self.planService = planService

        let now = Date()
        let currentMonth = TPCalendarDate.monthComponents(from: now)
        let pastMonthsCount = 12
        let futureMonthsCount = 24
        let startMonth = calendar.date(
            byAdding: .month,
            value: -pastMonthsCount,
            to: TPCalendarDate.date(from: currentMonth) ?? now
        ).map(TPCalendarDate.monthComponents(from:)) ?? currentMonth

        state = TPCalendarViewState(
            focusedMonth: currentMonth,
            availableMonths: TPCalendarDate.months(
                from: startMonth,
                count: pastMonthsCount + futureMonthsCount + 1
            ),
            availableYears: TPCalendarDate.years(
                around: calendar.component(.year, from: now),
                radius: 2
            ),
            periods: periodService.periods
        )

        router.$periodDraft
            .combineLatest(router.$editSession)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] draft, session in
                self?.updateState {
                    $0.periodDraft = draft
                    $0.editSession = session
                }
            }
            .store(in: &cancellables)

        periodService.$periods
            .receive(on: DispatchQueue.main)
            .sink { [weak self] periods in
                self?.updateState {
                    $0.periods = periods
                }
            }
            .store(in: &cancellables)
    }

    func toggleDisplayMode() {
        updateState {
            $0.displayMode = $0.displayMode == .month ? .year : .month
            if $0.displayMode == .year {
                let year = $0.focusedMonth.year
                    ?? TPCalendarDate.calendar.component(.year, from: Date())
                if !$0.availableYears.contains(year) {
                    $0.availableYears = TPCalendarDate.years(around: year, radius: 2)
                }
            }
        }
    }

    func focus(month: DateComponents) {
        updateState {
            $0.focusedMonth = DateComponents(year: month.year, month: month.month)
            $0.displayMode = .month
        }
    }

    func scrollToToday() {
        let now = Date()
        let currentMonth = TPCalendarDate.monthComponents(from: now)
        let currentYear = calendar.component(.year, from: now)

        updateState {
            $0.focusedMonth = currentMonth
            $0.scrollToFocusedRequestID += 1
            if $0.displayMode == .year, !$0.availableYears.contains(currentYear) {
                $0.availableYears = TPCalendarDate.years(around: currentYear, radius: 2)
            }
        }
    }

    func tapDay(_ day: DateComponents) {
        let tapped = normalized(day)

        if state.periodDraft == nil, state.selectionAnchor == nil, state.editSession == nil {
            let covering = periodsCovering(tapped)
            if !covering.isEmpty {
                router.presentEditSession(TPPeriodEditSession(periods: covering))
                return
            }
        }

        if let anchor = state.selectionAnchor {
            if TPCalendarDate.isSameDay(anchor, tapped) {
                clearSelectionAndDismiss()
                return
            }

            let range = TPCalendarDate.daysInRange(from: anchor, to: tapped)
            presentOrUpdateDraft(for: range, keepExistingID: false)
            return
        }

        if let draft = state.periodDraft {
            guard
                let first = state.selectedDates.compactMap(TPCalendarDate.date(from:)).min(),
                let last = state.selectedDates.compactMap(TPCalendarDate.date(from:)).max()
            else {
                return
            }

            let firstComponents = TPCalendarDate.dayComponents(from: first)
            let lastComponents = TPCalendarDate.dayComponents(from: last)
            let tappedDate = TPCalendarDate.date(from: tapped) ?? first
            let distanceToFirst = abs(calendar.dateComponents([.day], from: tappedDate, to: first).day ?? 0)
            let distanceToLast = abs(calendar.dateComponents([.day], from: tappedDate, to: last).day ?? 0)
            let anchor = distanceToFirst <= distanceToLast ? lastComponents : firstComponents
            let range = TPCalendarDate.daysInRange(from: anchor, to: tapped)
            presentOrUpdateDraft(for: range, keepExistingID: true, existing: draft)
            return
        }

        updateState(animated: true) {
            $0.selectionAnchor = tapped
            $0.selectedDates = [tapped]
        }
    }

    func longPressDay(_ day: DateComponents) {
        let tapped = normalized(day)
        router.dismissPeriodEditor()
        updateState(animated: true) {
            $0.editSession = nil
            $0.periodDraft = nil
            $0.selectionAnchor = tapped
            $0.selectedDates = [tapped]
        }
    }

    func colors(for day: DateComponents) -> [Color] {
        periodColors(for: day).map(\.color)
    }

    func periodColors(for day: DateComponents) -> [TPPeriodColor] {
        periodsCovering(day).map {
            TPPeriodColor(id: $0.id.uuidString, color: $0.color)
        }
    }

    func periodsCovering(_ day: DateComponents) -> [TPPeriod] {
        let normalizedDay = normalized(day)
        return state.periods
            .filter { period in
                period.dates.contains(where: { TPCalendarDate.isSameDay($0, normalizedDay) })
            }
            .sorted { lhs, rhs in
                periodStart(lhs) < periodStart(rhs)
            }
    }

    private func periodStart(_ period: TPPeriod) -> Date {
        period.dates
            .compactMap(TPCalendarDate.date(from:))
            .min() ?? .distantFuture
    }

    func isSelected(_ day: DateComponents) -> Bool {
        let normalizedDay = normalized(day)
        return state.selectedDates.contains(where: { TPCalendarDate.isSameDay($0, normalizedDay) })
    }

    func isToday(_ day: DateComponents) -> Bool {
        TPCalendarDate.isSameDay(normalized(day), TPCalendarDate.dayComponents(from: Date()))
    }

    func savePeriod(title: String?, emoji: String?, color: Color) {
        guard let draft = state.periodDraft else { return }

        periodService.add(
            TPPeriod(
                title: normalizedOptionalText(title),
                emoji: normalizedOptionalText(emoji),
                color: color,
                dates: draft.dates
            )
        )
        clearSelectionAndDismiss()
    }

    func updatePeriod(id: UUID, title: String?, emoji: String?, color: Color) {
        guard let existing = state.periods.first(where: { $0.id == id }) else { return }

        var updated = existing
        updated.title = normalizedOptionalText(title)
        updated.emoji = normalizedOptionalText(emoji)
        updated.color = color
        periodService.update(updated)
        clearSelectionAndDismiss()
    }

    func deletePeriod(id: UUID) {
        if let period = state.periods.first(where: { $0.id == id }) {
            let retained = state.periods.filter { $0.id != id }
            planService.deleteExclusiveDays(of: period, retainedPeriods: retained)
        }
        periodService.delete(id: id)

        if var session = state.editSession {
            session.periods.removeAll { $0.id == id }
            if session.periods.isEmpty {
                updateState {
                    $0.editSession = nil
                }
                router.editSession = nil
            } else {
                updateState {
                    $0.editSession = session
                }
                router.editSession = session
            }
        }
    }

    func cancelPeriodEditing() {
        clearSelectionAndDismiss()
    }

    private func presentOrUpdateDraft(
        for dates: Set<DateComponents>,
        keepExistingID: Bool,
        existing: TPPeriodDraft? = nil
    ) {
        let draft: TPPeriodDraft?
        if keepExistingID, let existing {
            draft = existing.updating(dates: dates)
        } else {
            draft = TPPeriodDraft.make(dates: dates)
        }

        guard let draft else {
            clearSelectionAndDismiss()
            return
        }

        updateState(animated: true) {
            $0.selectedDates = dates
            $0.selectionAnchor = nil
        }
        router.present(draft)
    }

    private func clearSelectionAndDismiss() {
        updateState(animated: true) {
            $0.selectedDates = []
            $0.selectionAnchor = nil
        }
        router.dismissPeriodEditor()
    }

    private func normalizedOptionalText(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (trimmed?.isEmpty == false) ? trimmed : nil
    }

    private func updateState(
        animated: Bool = false,
        _ mutate: (inout TPCalendarViewState) -> Void
    ) {
        var copy = state
        mutate(&copy)
        if animated {
            withAnimation(.smooth(duration: 0.34)) {
                state = copy
            }
        } else {
            state = copy
        }
    }

    private func normalized(_ day: DateComponents) -> DateComponents {
        DateComponents(year: day.year, month: day.month, day: day.day)
    }
}
