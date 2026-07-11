import Combine
import Foundation

@MainActor
final class TPCalendarRouter: ObservableObject {
    @Published var periodDraft: TPPeriodDraft?
    @Published var editSession: TPPeriodEditSession?

    func present(_ draft: TPPeriodDraft) {
        editSession = nil
        periodDraft = draft
    }

    func presentEditSession(_ session: TPPeriodEditSession) {
        periodDraft = nil
        editSession = session
    }

    func dismissPeriodEditor() {
        periodDraft = nil
        editSession = nil
    }
}
