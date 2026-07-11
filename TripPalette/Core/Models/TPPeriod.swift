import SwiftUI

struct TPPeriod: Identifiable, Equatable {
    let id: UUID
    var title: String?
    var emoji: String?
    var color: Color
    var dates: Set<DateComponents>

    init(
        id: UUID = UUID(),
        title: String? = nil,
        emoji: String? = nil,
        color: Color,
        dates: Set<DateComponents>
    ) {
        self.id = id
        self.title = title
        self.emoji = emoji
        self.color = color
        self.dates = dates
    }
}
