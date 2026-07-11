import SwiftUI
import UIKit

struct TPPeriodPlanView: View {
    @ObservedObject var viewModel: TPPeriodPlanViewModel
    @FocusState private var textFieldFocus: UUID?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 28) {
                    ForEach(viewModel.state.days) { day in
                        TPPlanDaySectionView(
                            day: day,
                            accentColor: viewModel.state.accentColor,
                            focusedBlockID: viewModel.state.focusedBlockID,
                            focusEpoch: viewModel.state.focusEpoch,
                            focusCursorAtEnd: viewModel.state.focusCursorAtEnd,
                            shouldDismissKeyboard: viewModel.state.focusedBlockID == nil,
                            textFieldFocus: $textFieldFocus,
                            onTextChange: { blockID, text in
                                viewModel.updateBlockText(dayID: day.id, blockID: blockID, text: text)
                            },
                            onURLChange: { blockID, url in
                                viewModel.updateBlockURL(dayID: day.id, blockID: blockID, url: url)
                            },
                            onDetailChange: { blockID, detail in
                                viewModel.updateBlockDetail(dayID: day.id, blockID: blockID, detail: detail)
                            },
                            onToggleTodo: { blockID in
                                viewModel.toggleTodo(dayID: day.id, blockID: blockID)
                            },
                            onToggleExpanded: { blockID in
                                viewModel.toggleExpanded(dayID: day.id, blockID: blockID)
                            },
                            onBackspaceWhenEmpty: { blockID in
                                viewModel.deleteBlock(
                                    dayID: day.id,
                                    blockID: blockID,
                                    placeCursorAtEndOfPrevious: true
                                )
                            },
                            onSubmitListItem: { blockID in
                                viewModel.insertListItem(dayID: day.id, after: blockID)
                            },
                            onBeganEditing: { blockID in
                                if viewModel.state.focusedBlockID != blockID {
                                    viewModel.focus(blockID: blockID)
                                }
                            },
                            onDidMoveCursorToEnd: {
                                viewModel.clearFocusCursorAtEnd()
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 96)
            }

            addToolbar
                .padding(.trailing, 16)
                .padding(.bottom, 12)
        }
        .background(Color.tp_backgroundPrimary)
        .navigationTitle(viewModel.state.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Сохранить") {
                    textFieldFocus = nil
                    viewModel.dismissKeyboard()
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil,
                        from: nil,
                        for: nil
                    )
                    viewModel.save()
                }
                .disabled(!viewModel.state.isDirty)
            }
        }
        .onChange(of: viewModel.state.focusedBlockID) { _, newValue in
            if let newValue {
                textFieldFocus = newValue
            }
        }
    }

    private var addToolbar: some View {
        HStack(spacing: 4) {
            toolbarButton(title: "Текст", systemImage: "text.alignleft") {
                viewModel.addBlock(kind: .text)
            }

            Menu {
                Button("Список", systemImage: "list.bullet") {
                    viewModel.addBlock(kind: .bullet)
                }
                Button("To-do", systemImage: "checklist") {
                    viewModel.addBlock(kind: .todo)
                }
                Button("Toggle", systemImage: "chevron.right.circle") {
                    viewModel.addBlock(kind: .toggle)
                }
            } label: {
                Image(systemName: "list.bullet")
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.tp_textPrimary)
                    .frame(width: 44, height: 40)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Список")

            toolbarButton(title: "Ссылка", systemImage: "link") {
                viewModel.addBlock(kind: .link)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .glassEffect(.regular.interactive(), in: .capsule)
    }

    private func toolbarButton(
        title: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.body.weight(.medium))
                .foregroundStyle(Color.tp_textPrimary)
                .frame(width: 44, height: 40)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}
