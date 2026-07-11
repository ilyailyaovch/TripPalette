import Foundation
import SwiftData

@Model
final class TPPeriodRecord {
    @Attribute(.unique) var id: UUID
    var title: String?
    var emoji: String?
    var colorHex: String
    var datesData: Data

    init(
        id: UUID,
        title: String?,
        emoji: String?,
        colorHex: String,
        datesData: Data
    ) {
        self.id = id
        self.title = title
        self.emoji = emoji
        self.colorHex = colorHex
        self.datesData = datesData
    }
}
