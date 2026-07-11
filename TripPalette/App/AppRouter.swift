import Combine
import SwiftUI

enum AppTab: Hashable {
    case calendar
    case periods
}

@MainActor
final class AppRouter: ObservableObject {
    @Published var selectedTab: AppTab = .calendar
}
