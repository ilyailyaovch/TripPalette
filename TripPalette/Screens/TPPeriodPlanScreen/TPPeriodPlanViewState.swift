import Foundation
import SwiftUI

struct TPPeriodPlanViewState: Equatable {
    var periodID: UUID
    var title: String
    var accentColor: Color
    var days: [TPDayPlan]
    var isDirty: Bool = false
    var focusedBlockID: UUID?
    var focusCursorAtEnd: Bool = false
    var focusEpoch: Int = 0
}
