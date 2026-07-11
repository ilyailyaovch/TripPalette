import SwiftUI

@MainActor
final class TPCalendarFactory {
    static func makeViewModel(
        periodService: TPPeriodService,
        planService: TPPeriodPlanService
    ) -> TPCalendarViewModel {
        TPCalendarViewModel(
            router: TPCalendarRouter(),
            periodService: periodService,
            planService: planService
        )
    }

    static func configure(viewModel: TPCalendarViewModel) -> some View {
        TPCalendarView(viewModel: viewModel)
    }
}
