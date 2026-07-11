import Foundation
import SwiftUI

@MainActor
final class TPPeriodPlanViewModel: ObservableObject {
    @Published private(set) var state: TPPeriodPlanViewState

    private let planService: TPPeriodPlanService

    init(period: TPPeriod, planService: TPPeriodPlanService) {
        self.planService = planService

        let days = Self.makeDays(for: period, planService: planService)
        state = TPPeriodPlanViewState(
            periodID: period.id,
            title: Self.displayTitle(for: period),
            accentColor: period.color,
            days: days
        )
    }

    func addBlock(kind: TPPlanBlockKind) {
        guard let dayID = targetDayID() else { return }
        addBlock(dayID: dayID, kind: kind)
    }

    func addBlock(dayID: String, kind: TPPlanBlockKind) {
        var newBlockID: UUID?
        let focusedID = state.focusedBlockID

        updateDay(id: dayID) { day in
            var insertIndex = day.blocks.count

            if let focusedID,
               let focusedIndex = day.blocks.firstIndex(where: { $0.id == focusedID }) {
                if day.blocks[focusedIndex].isEffectivelyEmpty {
                    day.blocks.remove(at: focusedIndex)
                    insertIndex = focusedIndex
                } else {
                    insertIndex = focusedIndex + 1
                }
            } else {
                day.blocks.removeAll { $0.kind == .text && $0.isEffectivelyEmpty }
                insertIndex = day.blocks.count
            }

            let block = TPPlanBlock.make(kind)
            newBlockID = block.id
            day.blocks.insert(block, at: min(insertIndex, day.blocks.count))
        }

        if let newBlockID {
            focus(blockID: newBlockID)
        }
    }

    private func targetDayID() -> String? {
        if let focusedBlockID = state.focusedBlockID,
           let day = state.days.first(where: { day in
               day.blocks.contains(where: { $0.id == focusedBlockID })
           }) {
            return day.id
        }
        return state.days.first?.id
    }

    func insertListItem(dayID: String, after blockID: UUID) {
        var copy = state
        guard let dayIndex = copy.days.firstIndex(where: { $0.id == dayID }) else { return }
        guard let blockIndex = copy.days[dayIndex].blocks.firstIndex(where: { $0.id == blockID }) else {
            return
        }

        let kind = copy.days[dayIndex].blocks[blockIndex].kind
        guard kind == .bullet || kind == .todo || kind == .toggle else { return }

        let newBlock = TPPlanBlock.make(kind)
        copy.days[dayIndex].blocks.insert(newBlock, at: blockIndex + 1)
        copy.focusedBlockID = newBlock.id
        copy.focusCursorAtEnd = false
        copy.focusEpoch += 1
        copy.isDirty = true
        state = copy
    }

    func focus(blockID: UUID?, cursorAtEnd: Bool = false) {
        var copy = state
        copy.focusedBlockID = blockID
        copy.focusCursorAtEnd = cursorAtEnd
        copy.focusEpoch += 1
        state = copy
    }

    func clearFocusCursorAtEnd() {
        guard state.focusCursorAtEnd else { return }
        var copy = state
        copy.focusCursorAtEnd = false
        state = copy
    }

    func dismissKeyboard() {
        var copy = state
        copy.focusedBlockID = nil
        copy.focusCursorAtEnd = false
        copy.focusEpoch += 1
        state = copy
    }

    func updateBlockText(dayID: String, blockID: UUID, text: String) {
        updateDay(id: dayID) { day in
            guard let index = day.blocks.firstIndex(where: { $0.id == blockID }) else { return }
            day.blocks[index].text = text
        }
    }

    func updateBlockURL(dayID: String, blockID: UUID, url: String) {
        updateDay(id: dayID) { day in
            guard let index = day.blocks.firstIndex(where: { $0.id == blockID }) else { return }
            day.blocks[index].url = url
        }
    }

    func toggleTodo(dayID: String, blockID: UUID) {
        updateDay(id: dayID) { day in
            guard let index = day.blocks.firstIndex(where: { $0.id == blockID }) else { return }
            day.blocks[index].isDone.toggle()
        }
    }

    func toggleExpanded(dayID: String, blockID: UUID) {
        updateDay(id: dayID) { day in
            guard let index = day.blocks.firstIndex(where: { $0.id == blockID }) else { return }
            day.blocks[index].isExpanded.toggle()
        }
    }

    func updateBlockDetail(dayID: String, blockID: UUID, detail: String) {
        updateDay(id: dayID) { day in
            guard let index = day.blocks.firstIndex(where: { $0.id == blockID }) else { return }
            day.blocks[index].detail = detail
        }
    }

    func deleteBlock(dayID: String, blockID: UUID, placeCursorAtEndOfPrevious: Bool = false) {
        var focusTarget: UUID?
        var copy = state

        guard let dayIndex = copy.days.firstIndex(where: { $0.id == dayID }) else { return }
        guard let blockIndex = copy.days[dayIndex].blocks.firstIndex(where: { $0.id == blockID }) else {
            return
        }

        if blockIndex > 0 {
            focusTarget = copy.days[dayIndex].blocks[blockIndex - 1].id
        } else if copy.days[dayIndex].blocks.count > 1 {
            focusTarget = copy.days[dayIndex].blocks[blockIndex + 1].id
        }

        copy.days[dayIndex].blocks.remove(at: blockIndex)

        if copy.days[dayIndex].blocks.isEmpty {
            let placeholder = TPPlanBlock.make(.text)
            copy.days[dayIndex].blocks = [placeholder]
            focusTarget = placeholder.id
            copy.focusCursorAtEnd = false
        } else {
            copy.focusCursorAtEnd = placeCursorAtEndOfPrevious && focusTarget != nil
        }

        copy.focusedBlockID = focusTarget
        copy.focusEpoch += 1
        copy.isDirty = true
        state = copy
    }

    func save() {
        for day in state.days {
            let blocksToSave = day.blocks.filter { !$0.isEffectivelyEmpty }
            planService.save(
                periodID: state.periodID,
                day: day.day,
                blocks: blocksToSave
            )
        }

        var copy = state
        copy.isDirty = false
        state = copy
    }

    private func updateDay(id: String, mutate: (inout TPDayPlan) -> Void) {
        var copy = state
        guard let index = copy.days.firstIndex(where: { $0.id == id }) else { return }
        mutate(&copy.days[index])
        copy.isDirty = true
        state = copy
    }

    private static func makeDays(
        for period: TPPeriod,
        planService: TPPeriodPlanService
    ) -> [TPDayPlan] {
        period.dates
            .compactMap { components -> (Date, DateComponents)? in
                guard let date = TPCalendarDate.date(from: components) else { return nil }
                return (date, DateComponents(
                    year: components.year,
                    month: components.month,
                    day: components.day
                ))
            }
            .sorted { $0.0 < $1.0 }
            .map { _, day in
                var blocks = planService.blocks(periodID: period.id, day: day)
                if blocks.isEmpty {
                    blocks = [.make(.text)]
                }
                return TPDayPlan(day: day, blocks: blocks)
            }
    }

    private static func displayTitle(for period: TPPeriod) -> String {
        let emoji = period.emoji?.trimmingCharacters(in: .whitespacesAndNewlines)
        let title = period.title?.trimmingCharacters(in: .whitespacesAndNewlines)

        switch (emoji?.isEmpty == false, title?.isEmpty == false) {
        case (true, true):
            return "\(emoji!) \(title!)"
        case (true, false):
            return emoji!
        case (false, true):
            return title!
        case (false, false):
            return "Без названия"
        }
    }
}

private extension TPPlanBlock {
    var isEffectivelyEmpty: Bool {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        switch kind {
        case .text, .bullet, .todo:
            return trimmedText.isEmpty
        case .toggle:
            let trimmedDetail = detail.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmedText.isEmpty && trimmedDetail.isEmpty
        case .link:
            let trimmedURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmedText.isEmpty && trimmedURL.isEmpty
        }
    }
}
