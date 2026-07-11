import SwiftUI

@MainActor
final class TPPeriodPlanFactory {
    static func configure(
        period: TPPeriod,
        planService: TPPeriodPlanService
    ) -> some View {
        TPPeriodPlanView(period: period, planService: planService)
    }
}
