import SwiftUI

@MainActor
final class TPPeriodPlanFactory {
    static func configure(
        period: TPPeriod,
        planService: TPPeriodPlanService
    ) -> some View {
        let viewModel = TPPeriodPlanViewModel(period: period, planService: planService)
        return TPPeriodPlanView(viewModel: viewModel)
    }
}
