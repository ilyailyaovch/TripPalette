import SwiftUI

@MainActor
final class TPCalendarFactory {
    static func configure(periodService: TPPeriodService) -> some View {
        let router = TPCalendarRouter()
        let viewModel = TPCalendarViewModel(router: router, periodService: periodService)
        return TPCalendarView(viewModel: viewModel)
    }
}
