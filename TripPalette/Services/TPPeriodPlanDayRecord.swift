import Foundation
import SwiftData

@Model
final class TPPeriodPlanDayRecord {
    @Attribute(.unique) var id: UUID
    var periodID: UUID
    var year: Int
    var month: Int
    var day: Int
    var blocksData: Data

    init(
        id: UUID = UUID(),
        periodID: UUID,
        year: Int,
        month: Int,
        day: Int,
        blocksData: Data
    ) {
        self.id = id
        self.periodID = periodID
        self.year = year
        self.month = month
        self.day = day
        self.blocksData = blocksData
    }
}
