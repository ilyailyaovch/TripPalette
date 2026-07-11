import SwiftData
import SwiftUI

@main
struct TripPaletteApp: App {
    @StateObject private var appRouter = AppRouter()
    @StateObject private var periodService: TPPeriodService
    @StateObject private var planService: TPPeriodPlanService

    private let modelContainer: ModelContainer

    init() {
        let container = try! ModelContainer(
            for: TPPeriodRecord.self,
            TPPeriodPlanDayRecord.self
        )
        modelContainer = container
        _periodService = StateObject(
            wrappedValue: TPPeriodService(modelContext: container.mainContext)
        )
        _planService = StateObject(
            wrappedValue: TPPeriodPlanService(modelContext: container.mainContext)
        )
    }

    var body: some Scene {
        WindowGroup {
            TPRootView(
                router: appRouter,
                periodService: periodService,
                planService: planService
            )
            .modelContainer(modelContainer)
            .preferredColorScheme(nil)
        }
    }
}
