import SwiftUI

@MainActor
final class TPPeriodsListFactory {
    static func configure(
        periodService: TPPeriodService,
        planService: TPPeriodPlanService
    ) -> some View {
        let viewModel = TPPeriodsListViewModel(
            periodService: periodService,
            planService: planService
        )
        return TPPeriodsListView(viewModel: viewModel, planService: planService)
    }
}
