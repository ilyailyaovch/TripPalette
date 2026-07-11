import SwiftUI

struct TPPlanDaySectionView: View {
    let day: TPDayPlan
    let accentColor: Color
    let focusedBlockID: UUID?
    let focusEpoch: Int
    let focusCursorAtEnd: Bool
    let shouldDismissKeyboard: Bool
    var textFieldFocus: FocusState<UUID?>.Binding
    let onTextChange: (UUID, String) -> Void
    let onURLChange: (UUID, String) -> Void
    let onDetailChange: (UUID, String) -> Void
    let onToggleTodo: (UUID) -> Void
    let onToggleExpanded: (UUID) -> Void
    let onBackspaceWhenEmpty: (UUID) -> Void
    let onSubmitListItem: (UUID) -> Void
    let onBeganEditing: (UUID) -> Void
    let onDidMoveCursorToEnd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(dayTitle)
                .font(.headline)
                .foregroundStyle(Color.tp_textPrimary)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(day.blocks) { block in
                    TPPlanBlockRowView(
                        block: block,
                        accentColor: accentColor,
                        isFocused: focusedBlockID == block.id,
                        focusEpoch: focusEpoch,
                        moveCursorToEnd: focusCursorAtEnd && focusedBlockID == block.id,
                        shouldDismissKeyboard: shouldDismissKeyboard,
                        textFieldFocus: textFieldFocus,
                        onTextChange: { onTextChange(block.id, $0) },
                        onURLChange: { onURLChange(block.id, $0) },
                        onDetailChange: { onDetailChange(block.id, $0) },
                        onToggleTodo: { onToggleTodo(block.id) },
                        onToggleExpanded: { onToggleExpanded(block.id) },
                        onBackspaceWhenEmpty: { onBackspaceWhenEmpty(block.id) },
                        onSubmitListItem: { onSubmitListItem(block.id) },
                        onBeganEditing: { onBeganEditing(block.id) },
                        onDidMoveCursorToEnd: onDidMoveCursorToEnd
                    )
                }
            }
        }
    }

    private var dayTitle: String {
        guard let date = TPCalendarDate.date(from: day.day) else {
            return "День"
        }
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.setLocalizedDateFormatFromTemplate("EEEEdMMMMy")
        return formatter.string(from: date)
    }
}
