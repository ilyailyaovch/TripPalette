import Foundation

struct TPPeriodEditSession: Identifiable, Equatable {
    let id: UUID
    var periods: [TPPeriod]

    init(id: UUID = UUID(), periods: [TPPeriod]) {
        self.id = id
        self.periods = periods
    }

    var isMultiple: Bool {
        periods.count > 1
    }
}
