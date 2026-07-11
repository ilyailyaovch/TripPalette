import SwiftUI

struct TPRootView: View {
    @ObservedObject var router: AppRouter
    @ObservedObject var periodService: TPPeriodService
    @ObservedObject var planService: TPPeriodPlanService

    var body: some View {
        TabView(selection: $router.selectedTab) {
            TPCalendarFactory.configure(periodService: periodService)
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
    }
}
