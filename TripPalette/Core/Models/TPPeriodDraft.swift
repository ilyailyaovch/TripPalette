import Foundation

struct TPPeriodDraft: Identifiable, Equatable {
    let id: UUID
    var dates: Set<DateComponents>

    private init(id: UUID, dates: Set<DateComponents>) {
        self.id = id
        self.dates = dates
    }

    static func make(dates: Set<DateComponents>) -> TPPeriodDraft? {
        guard dates.count >= 2 else { return nil }
        return TPPeriodDraft(id: UUID(), dates: dates)
    }

    func updating(dates: Set<DateComponents>) -> TPPeriodDraft? {
        guard dates.count >= 2 else { return nil }
        return TPPeriodDraft(id: id, dates: dates)
    }
}
