import SwiftUI

struct TPRootView: View {
    @ObservedObject var router: AppRouter
    @ObservedObject var periodService: TPPeriodService
    @ObservedObject var planService: TPPeriodPlanService
    @StateObject private var calendarViewModel: TPCalendarViewModel

    init(
        router: AppRouter,
        periodService: TPPeriodService,
        planService: TPPeriodPlanService
    ) {
        self.router = router
        self.periodService = periodService
        self.planService = planService
        _calendarViewModel = StateObject(
            wrappedValue: TPCalendarFactory.makeViewModel(
                periodService: periodService,
                planService: planService
            )
        )
    }

    var body: some View {
        TabView(selection: $router.selectedTab) {
            TPCalendarFactory.configure(viewModel: calendarViewModel)
                .tabItem {
                    Label("Календарь", systemImage: "calendar")
                }
                .tag(AppTab.calendar)

            TPPeriodsListFactory.configure(
                periodService: periodService,
                planService: planService
            )
            .tabItem {
                Label("Планы", systemImage: "map")
            }
            .tag(AppTab.periods)
        }
        .tint(Color.tp_tint)
        .background(Color.tp_backgroundPrimary)
        .background {
            TPTabBarReselectHandler { index in
                if index == 0 {
                    calendarViewModel.scrollToToday()
                }
            }
        }
        .onChange(of: router.selectedTab) { _, newValue in
            if newValue == .calendar {
                calendarViewModel.scrollToToday()
            }
        }
    }
}
