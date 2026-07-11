import Combine
import Foundation

@MainActor
final class TPPeriodsListViewModel: ObservableObject {
    @Published private(set) var state: TPPeriodsListViewState

    private let periodService: TPPeriodService
    private let planService: TPPeriodPlanService
    private var cancellables = Set<AnyCancellable>()

    private enum StorageKey {
        static let sortOrder = "tp.periodsList.sortOrder"
        static let showOnlyUpcoming = "tp.periodsList.showOnlyUpcoming"
    }

    init(periodService: TPPeriodService, planService: TPPeriodPlanService) {
        self.periodService = periodService
        self.planService = planService

        let defaults = UserDefaults.standard
        let sortOrder = TPPeriodsListSortOrder(
            rawValue: defaults.string(forKey: StorageKey.sortOrder) ?? ""
        ) ?? .startAscending
        let showOnlyUpcoming = defaults.object(forKey: StorageKey.showOnlyUpcoming) as? Bool ?? false

        state = TPPeriodsListViewState(
            sourcePeriods: periodService.periods,
            sortOrder: sortOrder,
            showOnlyUpcoming: showOnlyUpcoming
        )

        periodService.$periods
            .receive(on: DispatchQueue.main)
            .sink { [weak self] periods in
                self?.updateState {
                    $0.sourcePeriods = periods
                }
            }
            .store(in: &cancellables)
    }

    func setSortOrder(_ sortOrder: TPPeriodsListSortOrder) {
        UserDefaults.standard.set(sortOrder.rawValue, forKey: StorageKey.sortOrder)
        updateState {
            $0.sortOrder = sortOrder
        }
    }

    func setShowOnlyUpcoming(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: StorageKey.showOnlyUpcoming)
        updateState {
            $0.showOnlyUpcoming = value
        }
    }

    func deletePeriod(id: UUID) {
        planService.deleteAll(for: id)
        periodService.delete(id: id)
    }

    private func updateState(_ mutate: (inout TPPeriodsListViewState) -> Void) {
        var copy = state
        mutate(&copy)
        state = copy
    }
}
